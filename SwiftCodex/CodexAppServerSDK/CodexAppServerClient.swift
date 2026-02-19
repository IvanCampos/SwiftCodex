import Foundation
import CryptoKit
import Network

public struct AppServerLaunchConfiguration {
    public var executable: String
    public var arguments: [String]
    public var workingDirectory: String?
    public var environment: [String: String]?

    public init(
        executable: String = "/usr/bin/env",
        arguments: [String] = ["codex", "app-server", "--listen", "ws://127.0.0.1:4500"],
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) {
        self.executable = executable
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environment = environment
    }
}

@MainActor
public final class CodexAppServerClient {
    public let inboundMessages: AsyncStream<AppServerInboundMessage>

    private let launchConfiguration: AppServerLaunchConfiguration
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

#if os(macOS)
    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutTask: Task<Void, Never>?
    private var stderrTask: Task<Void, Never>?
#endif

    private var webSocketConnection: NWConnection?
    private var webSocketReaderTask: Task<Void, Never>?
    private var webSocketInboundBuffer = Data()
    private var webSocketTextFragmentBuffer = Data()

    private var continuation: AsyncStream<AppServerInboundMessage>.Continuation?
    private var pendingRequests: [JSONRPCID: CheckedContinuation<JSONValue, Error>] = [:]
    private var nextRequestID: Int64 = 1

    public init(launchConfiguration: AppServerLaunchConfiguration = AppServerLaunchConfiguration()) {
        self.launchConfiguration = launchConfiguration
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        var streamContinuation: AsyncStream<AppServerInboundMessage>.Continuation?
        self.inboundMessages = AsyncStream { continuation in
            streamContinuation = continuation
        }
        self.continuation = streamContinuation
    }

    deinit {
#if os(macOS)
        stdoutTask?.cancel()
        stderrTask?.cancel()
        process?.terminate()
#endif
        webSocketReaderTask?.cancel()
        webSocketConnection?.cancel()
    }

    public func connect() throws {
#if os(macOS)
        guard !isConnected else {
            throw CodexAppServerError.processAlreadyRunning
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchConfiguration.executable)
        process.arguments = launchConfiguration.arguments

        if let workingDirectory = launchConfiguration.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        if let environment = launchConfiguration.environment {
            process.environment = environment
        }

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        process.terminationHandler = { [weak self] terminatedProcess in
            Task { @MainActor in
                self?.didTerminate(with: terminatedProcess.terminationStatus)
            }
        }

        try process.run()

        self.process = process
        self.stdinHandle = stdinPipe.fileHandleForWriting

        startStdoutLoop(stdoutPipe.fileHandleForReading)
        startStderrLoop(stderrPipe.fileHandleForReading)
#else
        throw CodexAppServerError.unsupportedPlatform(
            "Process-based stdio transport is only available on macOS. Use connectWebSocket(url:)."
        )
#endif
    }

    public func connectWebSocket(url: URL) async throws {
        guard !isConnected else {
            throw CodexAppServerError.processAlreadyRunning
        }

        let connection = try await openWebSocketConnection(url: url)
        webSocketConnection = connection
        webSocketInboundBuffer.removeAll(keepingCapacity: true)
        webSocketTextFragmentBuffer.removeAll(keepingCapacity: true)
        startWebSocketLoop(connection)
    }

    public func disconnect() {
#if os(macOS)
        stdoutTask?.cancel()
        stdoutTask = nil

        stderrTask?.cancel()
        stderrTask = nil

        stdinHandle = nil

        if let process {
            process.terminationHandler = nil
            if process.isRunning {
                process.terminate()
            }
        }
        process = nil
#endif

        webSocketReaderTask?.cancel()
        webSocketReaderTask = nil

        webSocketConnection?.cancel()
        webSocketConnection = nil
        webSocketInboundBuffer.removeAll(keepingCapacity: true)
        webSocketTextFragmentBuffer.removeAll(keepingCapacity: true)

        failPendingRequests(with: CodexAppServerError.notConnected)
        continuation?.yield(.disconnected(exitCode: nil))
    }

    public func initialize(_ params: InitializeParams) async throws -> InitializeResult {
        try await call(.initialize, params: params, as: InitializeResult.self)
    }

    public func initialized() throws {
        try sendNotification(method: "initialized")
    }

    public func call<Result: Decodable, Params: Encodable>(
        _ method: AppServerMethod,
        params: Params,
        as resultType: Result.Type = Result.self
    ) async throws -> Result {
        let raw = try await performCallRaw(method: method.rawValue, params: AnyEncodable(params))
        return try JSONValueCoding.decode(resultType, from: raw)
    }

    public func call<Result: Decodable>(
        _ method: AppServerMethod,
        as resultType: Result.Type = Result.self
    ) async throws -> Result {
        let raw = try await performCallRaw(method: method.rawValue, params: nil)
        return try JSONValueCoding.decode(resultType, from: raw)
    }

    public func callWithRetry<Result: Decodable, Params: Encodable>(
        _ method: AppServerMethod,
        params: Params,
        retryPolicy: RetryPolicy = .appServerDefault,
        as resultType: Result.Type = Result.self
    ) async throws -> Result {
        var attempt = 0

        while true {
            attempt += 1

            do {
                return try await call(method, params: params, as: resultType)
            } catch CodexAppServerError.rpc(let error) where error.code == -32001 && attempt < retryPolicy.maxAttempts {
                let delay = retryPolicy.delayNanoseconds(forAttempt: attempt)
                try await Task.sleep(nanoseconds: delay)
            }
        }
    }

    public func callRaw(method: String, params: JSONValue?) async throws -> JSONValue {
        let anyParams: AnyEncodable?
        if let params {
            anyParams = AnyEncodable(params)
        } else {
            anyParams = nil
        }
        return try await performCallRaw(method: method, params: anyParams)
    }

    public func sendNotification(method: String) throws {
        try send(JSONRPCOutgoingEnvelope(method: method))
    }

    public func sendNotification<Params: Encodable>(method: String, params: Params) throws {
        try send(JSONRPCOutgoingEnvelope(method: method, params: AnyEncodable(params)))
    }

    public func respond<Result: Encodable>(to request: AppServerRequestMessage, result: Result) throws {
        let envelope = JSONRPCOutgoingEnvelope(id: request.id, result: AnyEncodable(result))
        try send(envelope)
    }

    public func respond(to request: AppServerRequestMessage, error: JSONRPCErrorObject) throws {
        let envelope = JSONRPCOutgoingEnvelope(id: request.id, error: error)
        try send(envelope)
    }

    // MARK: - Endpoint Convenience

    public func threadStart(_ params: ThreadStartParams) async throws -> ThreadEnvelope {
        try await call(.threadStart, params: params, as: ThreadEnvelope.self)
    }

    public func threadResume(_ params: ThreadResumeParams) async throws -> ThreadEnvelope {
        try await call(.threadResume, params: params, as: ThreadEnvelope.self)
    }

    public func threadFork(_ params: ThreadForkParams) async throws -> ThreadEnvelope {
        try await call(.threadFork, params: params, as: ThreadEnvelope.self)
    }

    public func threadList(_ params: ThreadListParams) async throws -> ThreadListResult {
        try await call(.threadList, params: params, as: ThreadListResult.self)
    }

    public func threadLoadedList() async throws -> StringListResult {
        try await call(.threadLoadedList, as: StringListResult.self)
    }

    public func threadRead(_ params: ThreadReadParams) async throws -> ThreadEnvelope {
        try await call(.threadRead, params: params, as: ThreadEnvelope.self)
    }

    public func threadArchive(_ params: ThreadIDParams) async throws -> EmptyObject {
        try await call(.threadArchive, params: params, as: EmptyObject.self)
    }

    public func threadNameSet(_ params: ThreadNameSetParams) async throws -> EmptyObject {
        try await call(.threadNameSet, params: params, as: EmptyObject.self)
    }

    public func threadUnarchive(_ params: ThreadIDParams) async throws -> ThreadEnvelope {
        try await call(.threadUnarchive, params: params, as: ThreadEnvelope.self)
    }

    public func threadCompactStart(_ params: ThreadIDParams) async throws -> EmptyObject {
        try await call(.threadCompactStart, params: params, as: EmptyObject.self)
    }

    public func threadBackgroundTerminalsClean(_ params: ThreadIDParams) async throws -> EmptyObject {
        try await call(.threadBackgroundTerminalsClean, params: params, as: EmptyObject.self)
    }

    public func threadRollback<Params: Encodable>(_ params: Params) async throws -> ThreadEnvelope {
        try await call(.threadRollback, params: params, as: ThreadEnvelope.self)
    }

    public func turnStart(_ params: TurnStartParams) async throws -> TurnEnvelope {
        try await call(.turnStart, params: params, as: TurnEnvelope.self)
    }

    public func turnSteer(_ params: TurnSteerParams) async throws -> TurnIDEnvelope {
        try await call(.turnSteer, params: params, as: TurnIDEnvelope.self)
    }

    public func turnInterrupt(_ params: TurnInterruptParams) async throws -> EmptyObject {
        try await call(.turnInterrupt, params: params, as: EmptyObject.self)
    }

    public func reviewStart(_ params: ReviewStartParams) async throws -> ReviewStartResult {
        try await call(.reviewStart, params: params, as: ReviewStartResult.self)
    }

    public func commandExec(_ params: CommandExecParams) async throws -> CommandExecResult {
        try await call(.commandExec, params: params, as: CommandExecResult.self)
    }

    public func modelList(_ params: ModelListParams = ModelListParams()) async throws -> ModelListResult {
        try await call(.modelList, params: params, as: ModelListResult.self)
    }

    public func experimentalFeatureList(_ params: CursorParams = CursorParams()) async throws -> ExperimentalFeatureListResult {
        try await call(.experimentalFeatureList, params: params, as: ExperimentalFeatureListResult.self)
    }

    public func collaborationModeList() async throws -> CollaborationModeListResult {
        try await call(.collaborationModeList, as: CollaborationModeListResult.self)
    }

    public func skillsList(_ params: SkillsListParams = SkillsListParams()) async throws -> SkillsListResult {
        try await call(.skillsList, params: params, as: SkillsListResult.self)
    }

    public func skillsRemoteList<Params: Encodable>(_ params: Params) async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.skillsRemoteList.rawValue, params: AnyEncodable(params))
    }

    public func skillsRemoteExport<Params: Encodable>(_ params: Params) async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.skillsRemoteExport.rawValue, params: AnyEncodable(params))
    }

    public func appList(_ params: AppListParams = AppListParams()) async throws -> AppListResult {
        try await call(.appList, params: params, as: AppListResult.self)
    }

    public func skillsConfigWrite(_ params: SkillsConfigWriteParams) async throws -> EmptyObject {
        try await call(.skillsConfigWrite, params: params, as: EmptyObject.self)
    }

    public func mcpServerOAuthLogin(_ params: MCPServerOAuthLoginParams) async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.mcpServerOAuthLogin.rawValue, params: AnyEncodable(params))
    }

    public func toolRequestUserInput(_ params: ToolRequestUserInputParams) async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.toolRequestUserInput.rawValue, params: AnyEncodable(params))
    }

    public func configMCPServerReload() async throws -> EmptyObject {
        try await call(.configMCPServerReload, as: EmptyObject.self)
    }

    public func mcpServerStatusList(_ params: CursorParams = CursorParams()) async throws -> MCPServerStatusListResult {
        try await call(.mcpServerStatusList, params: params, as: MCPServerStatusListResult.self)
    }

    public func windowsSandboxSetupStart(_ params: WindowsSandboxSetupStartParams) async throws -> WindowsSandboxSetupStartResult {
        try await call(.windowsSandboxSetupStart, params: params, as: WindowsSandboxSetupStartResult.self)
    }

    public func feedbackUpload(_ params: FeedbackUploadParams) async throws -> FeedbackUploadResult {
        try await call(.feedbackUpload, params: params, as: FeedbackUploadResult.self)
    }

    public func configRead() async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.configRead.rawValue, params: nil)
    }

    public func configValueWrite(_ params: ConfigValueWriteParams) async throws -> EmptyObject {
        try await call(.configValueWrite, params: params, as: EmptyObject.self)
    }

    public func configBatchWrite(_ params: ConfigBatchWriteParams) async throws -> EmptyObject {
        try await call(.configBatchWrite, params: params, as: EmptyObject.self)
    }

    public func configRequirementsRead() async throws -> JSONValue {
        try await performCallRaw(method: AppServerMethod.configRequirementsRead.rawValue, params: nil)
    }

    public func accountRead(_ params: AccountReadParams = AccountReadParams()) async throws -> AccountReadResult {
        try await call(.accountRead, params: params, as: AccountReadResult.self)
    }

    public func accountLoginStart(_ params: AccountLoginStartParams) async throws -> AccountLoginStartResult {
        try await call(.accountLoginStart, params: params, as: AccountLoginStartResult.self)
    }

    public func accountLoginCancel(_ params: AccountLoginCancelParams) async throws -> EmptyObject {
        try await call(.accountLoginCancel, params: params, as: EmptyObject.self)
    }

    public func accountLogout() async throws -> EmptyObject {
        try await call(.accountLogout, as: EmptyObject.self)
    }

    public func accountRateLimitsRead() async throws -> AccountRateLimitsReadResult {
        try await call(.accountRateLimitsRead, as: AccountRateLimitsReadResult.self)
    }

    // MARK: - Internal send/receive

    private var isConnected: Bool {
#if os(macOS)
        if process != nil, stdinHandle != nil {
            return true
        }
#endif
        return webSocketConnection != nil
    }

    private func performCallRaw(method: String, params: AnyEncodable?) async throws -> JSONValue {
        guard isConnected else {
            throw CodexAppServerError.notConnected
        }

        let id = JSONRPCID.int(nextRequestID)
        nextRequestID += 1

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation

            let outbound = JSONRPCOutgoingEnvelope(id: id, method: method, params: params)

            do {
                try send(outbound)
            } catch {
                pendingRequests[id] = nil
                continuation.resume(throwing: error)
            }
        }
    }

    private func send(_ envelope: JSONRPCOutgoingEnvelope) throws {
        let data = try encoder.encode(envelope)

#if os(macOS)
        if let stdinHandle {
            var line = data
            line.append(0x0A)

            do {
                try stdinHandle.write(contentsOf: line)
                return
            } catch {
                throw CodexAppServerError.failedToEncodeOutboundMessage
            }
        }
#endif

        if let webSocketConnection {
            guard let text = String(data: data, encoding: .utf8) else {
                throw CodexAppServerError.failedToEncodeOutboundMessage
            }

            let frame = Self.makeWebSocketFrame(opcode: 0x1, payload: Data(text.utf8), masked: true)
            webSocketConnection.send(content: frame, completion: .contentProcessed { [weak self] error in
                guard let error else { return }
                guard let self else { return }
                Task { @MainActor in
                    self.continuation?.yield(.stderr("websocket send failed: \(error.localizedDescription)"))
                    self.didTerminate(with: nil)
                }
            })
            return
        }

        throw CodexAppServerError.notConnected
    }

#if os(macOS)
    private func startStdoutLoop(_ handle: FileHandle) {
        stdoutTask = Task { [weak self] in
            guard let self else { return }

            do {
                for try await line in handle.bytes.lines {
                    await self.handleInboundText(String(line))
                }
            } catch {
                await self.failPendingRequests(with: error)
            }

            await self.didTerminate(with: self.process?.terminationStatus)
        }
    }

    private func startStderrLoop(_ handle: FileHandle) {
        stderrTask = Task { [weak self] in
            guard let self else { return }

            do {
                for try await line in handle.bytes.lines {
                    await self.continuation?.yield(.stderr(String(line)))
                }
            } catch {
                await self.continuation?.yield(.stderr("stderr stream failed: \(error.localizedDescription)"))
            }
        }
    }
#endif

    private struct WebSocketFrame {
        let fin: Bool
        let opcode: UInt8
        let payload: Data
    }

    private func openWebSocketConnection(url: URL) async throws -> NWConnection {
        guard let scheme = url.scheme?.lowercased(), scheme == "ws" || scheme == "wss" else {
            throw CodexAppServerError.invalidWebSocketURL("URL must use ws:// or wss://.")
        }

        guard let hostString = url.host(), hostString.isEmpty == false else {
            throw CodexAppServerError.invalidWebSocketURL("URL must include a host.")
        }

        let isSecure = scheme == "wss"
        let resolvedPort = url.port ?? (isSecure ? 443 : 80)

        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(resolvedPort)) else {
            throw CodexAppServerError.invalidWebSocketURL("Invalid websocket port '\(resolvedPort)'.")
        }

        let parameters: NWParameters
        if isSecure {
            parameters = NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options())
        } else {
            parameters = .tcp
        }

        let connection = NWConnection(host: NWEndpoint.Host(hostString), port: endpointPort, using: parameters)
        try await waitUntilReady(connection)
        try await performWebSocketHandshake(
            on: connection,
            url: url,
            host: hostString,
            port: resolvedPort,
            isSecure: isSecure
        )
        return connection
    }

    private func waitUntilReady(_ connection: NWConnection) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                final class ResumeState: @unchecked Sendable {
                    private let lock = NSLock()
                    private var resumed = false

                    func markResumedIfNeeded() -> Bool {
                        lock.lock()
                        defer { lock.unlock() }

                        if resumed {
                            return false
                        }

                        resumed = true
                        return true
                    }
                }

                final class TimeoutController: @unchecked Sendable {
                    private let lock = NSLock()
                    private var timeoutTask: Task<Void, Never>?

                    func set(_ task: Task<Void, Never>) {
                        lock.lock()
                        timeoutTask = task
                        lock.unlock()
                    }

                    func cancel() {
                        lock.lock()
                        let task = timeoutTask
                        timeoutTask = nil
                        lock.unlock()
                        task?.cancel()
                    }
                }

                let resumeState = ResumeState()
                let timeoutController = TimeoutController()

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        guard resumeState.markResumedIfNeeded() else { return }
                        timeoutController.cancel()
                        continuation.resume(returning: ())
                    case .waiting(let error):
                        // Treat waiting as a connection failure for explicit host:port websocket dials.
                        guard resumeState.markResumedIfNeeded() else { return }
                        timeoutController.cancel()
                        connection.cancel()
                        continuation.resume(throwing: error)
                    case .failed(let error):
                        guard resumeState.markResumedIfNeeded() else { return }
                        timeoutController.cancel()
                        continuation.resume(throwing: error)
                    case .cancelled:
                        guard resumeState.markResumedIfNeeded() else { return }
                        timeoutController.cancel()
                        continuation.resume(throwing: CodexAppServerError.notConnected)
                    default:
                        break
                    }
                }

                connection.start(queue: DispatchQueue.global(qos: .userInitiated))

                timeoutController.set(Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    guard resumeState.markResumedIfNeeded() else { return }
                    connection.cancel()
                    continuation.resume(
                        throwing: CodexAppServerError.websocketHandshakeFailed(
                            "Timed out while connecting to websocket server."
                        )
                    )
                })
            }
        } onCancel: {
            connection.cancel()
        }
    }

    private func performWebSocketHandshake(
        on connection: NWConnection,
        url: URL,
        host: String,
        port: Int,
        isSecure: Bool
    ) async throws {
        let key = Self.makeWebSocketKey()
        let path = Self.webSocketPath(for: url)
        let hostHeader = Self.webSocketHostHeader(host: host, port: port, isSecure: isSecure)

        var request = ""
        request += "GET \(path) HTTP/1.1\r\n"
        request += "Host: \(hostHeader)\r\n"
        request += "Upgrade: websocket\r\n"
        request += "Connection: Upgrade\r\n"
        request += "Sec-WebSocket-Version: 13\r\n"
        request += "Sec-WebSocket-Key: \(key)\r\n"
        request += "\r\n"

        guard let requestData = request.data(using: .utf8) else {
            throw CodexAppServerError.websocketHandshakeFailed("Failed to encode websocket handshake request.")
        }

        try await sendRaw(requestData, over: connection)

        var responseData = Data()
        while Self.httpHeaderTerminatorRange(in: responseData) == nil {
            let chunk = try await receiveRaw(from: connection)
            if chunk.isEmpty {
                continue
            }

            responseData.append(chunk)

            if responseData.count > 64 * 1024 {
                throw CodexAppServerError.websocketHandshakeFailed("Handshake response headers exceeded maximum size.")
            }
        }

        guard let headerRange = Self.httpHeaderTerminatorRange(in: responseData) else {
            throw CodexAppServerError.websocketHandshakeFailed("Handshake response was incomplete.")
        }

        let headerData = responseData.prefix(upTo: headerRange.upperBound)
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            throw CodexAppServerError.websocketHandshakeFailed("Handshake response was not valid UTF-8.")
        }

        let lines = headerText.components(separatedBy: "\r\n").filter { $0.isEmpty == false }
        guard let statusLine = lines.first, statusLine.contains("101") else {
            throw CodexAppServerError.websocketHandshakeFailed("Server did not accept websocket upgrade.")
        }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let separator = line.firstIndex(of: ":") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
            headers[key] = value
        }

        let expectedAccept = Self.webSocketAcceptValue(for: key)
        guard headers["sec-websocket-accept"] == expectedAccept else {
            throw CodexAppServerError.websocketHandshakeFailed("Handshake accept key did not match.")
        }

        if headerRange.upperBound < responseData.endIndex {
            webSocketInboundBuffer.append(contentsOf: responseData[headerRange.upperBound...])
        }
    }

    private func sendRaw(_ data: Data, over connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }

    private func receiveRaw(from connection: NWConnection, maximumLength: Int = 16_384) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let data, data.isEmpty == false {
                    continuation.resume(returning: data)
                    return
                }

                if isComplete {
                    continuation.resume(throwing: CodexAppServerError.terminated(-1))
                    return
                }

                continuation.resume(returning: Data())
            }
        }
    }

    private func startWebSocketLoop(_ connection: NWConnection) {
        webSocketReaderTask?.cancel()
        webSocketReaderTask = Task { [weak self] in
            guard let self else { return }

            do {
                if self.webSocketInboundBuffer.isEmpty == false {
                    try await self.processWebSocketInboundBuffer(connection: connection)
                }

                while !Task.isCancelled {
                    let chunk = try await self.receiveRaw(from: connection)
                    if chunk.isEmpty {
                        continue
                    }

                    self.webSocketInboundBuffer.append(chunk)
                    try await self.processWebSocketInboundBuffer(connection: connection)
                }
            } catch {
                if Task.isCancelled {
                    return
                }

                self.continuation?.yield(.stderr("websocket receive failed: \(error.localizedDescription)"))
                self.didTerminate(with: nil)
            }
        }
    }

    private func processWebSocketInboundBuffer(connection: NWConnection) async throws {
        while let frame = try Self.parseWebSocketFrame(from: &webSocketInboundBuffer) {
            try await handleWebSocketFrame(frame, connection: connection)
        }
    }

    private func handleWebSocketFrame(_ frame: WebSocketFrame, connection: NWConnection) async throws {
        switch frame.opcode {
        case 0x1:
            if frame.fin {
                guard let text = String(data: frame.payload, encoding: .utf8) else {
                    continuation?.yield(.stderr("Received non-UTF8 websocket text frame."))
                    return
                }
                handleInboundText(text)
            } else {
                webSocketTextFragmentBuffer = frame.payload
            }
        case 0x0:
            guard webSocketTextFragmentBuffer.isEmpty == false else {
                return
            }

            webSocketTextFragmentBuffer.append(frame.payload)

            if frame.fin {
                guard let text = String(data: webSocketTextFragmentBuffer, encoding: .utf8) else {
                    continuation?.yield(.stderr("Received non-UTF8 websocket continuation frame."))
                    webSocketTextFragmentBuffer.removeAll(keepingCapacity: true)
                    return
                }

                webSocketTextFragmentBuffer.removeAll(keepingCapacity: true)
                handleInboundText(text)
            }
        case 0x8:
            let closeFrame = Self.makeWebSocketFrame(opcode: 0x8, payload: Data(), masked: true)
            connection.send(content: closeFrame, completion: .idempotent)
            didTerminate(with: nil)
        case 0x9:
            let pongFrame = Self.makeWebSocketFrame(opcode: 0xA, payload: frame.payload, masked: true)
            connection.send(content: pongFrame, completion: .idempotent)
        case 0xA:
            break
        default:
            break
        }
    }

    private static func webSocketPath(for url: URL) -> String {
        let path = url.path.isEmpty ? "/" : url.path
        if let query = url.query, query.isEmpty == false {
            return "\(path)?\(query)"
        }
        return path
    }

    private static func webSocketHostHeader(host: String, port: Int, isSecure: Bool) -> String {
        let defaultPort = isSecure ? 443 : 80
        if port == defaultPort {
            return host
        }
        return "\(host):\(port)"
    }

    private static func makeWebSocketKey() -> String {
        Data(randomBytes(count: 16)).base64EncodedString()
    }

    private static func webSocketAcceptValue(for key: String) -> String {
        let magic = key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let digest = Insecure.SHA1.hash(data: Data(magic.utf8))
        return Data(digest).base64EncodedString()
    }

    private static func httpHeaderTerminatorRange(in data: Data) -> Range<Data.Index>? {
        data.range(of: Data([0x0D, 0x0A, 0x0D, 0x0A]))
    }

    private static func parseWebSocketFrame(from buffer: inout Data) throws -> WebSocketFrame? {
        let bytes = [UInt8](buffer)
        guard bytes.count >= 2 else {
            return nil
        }

        var cursor = 2
        let first = bytes[0]
        let second = bytes[1]

        let fin = (first & 0x80) != 0
        let opcode = first & 0x0F
        let masked = (second & 0x80) != 0

        var payloadLength = Int(second & 0x7F)
        if payloadLength == 126 {
            guard bytes.count >= cursor + 2 else {
                return nil
            }

            payloadLength = Int(UInt16(bytes[cursor]) << 8 | UInt16(bytes[cursor + 1]))
            cursor += 2
        } else if payloadLength == 127 {
            guard bytes.count >= cursor + 8 else {
                return nil
            }

            var value: UInt64 = 0
            for index in 0..<8 {
                value = (value << 8) | UInt64(bytes[cursor + index])
            }

            guard value <= UInt64(Int.max) else {
                throw CodexAppServerError.websocketProtocolViolation("Websocket payload exceeds supported size.")
            }

            payloadLength = Int(value)
            cursor += 8
        }

        var maskKey: [UInt8] = []
        if masked {
            guard bytes.count >= cursor + 4 else {
                return nil
            }

            maskKey = Array(bytes[cursor..<(cursor + 4)])
            cursor += 4
        }

        guard bytes.count >= cursor + payloadLength else {
            return nil
        }

        var payload = Array(bytes[cursor..<(cursor + payloadLength)])
        if masked {
            for index in payload.indices {
                payload[index] ^= maskKey[index % 4]
            }
        }

        let consumed = cursor + payloadLength
        buffer.removeFirst(consumed)

        return WebSocketFrame(fin: fin, opcode: opcode, payload: Data(payload))
    }

    private static func makeWebSocketFrame(opcode: UInt8, payload: Data, masked: Bool) -> Data {
        var frame = Data()
        frame.append(0x80 | (opcode & 0x0F))

        let length = payload.count
        if length < 126 {
            frame.append((masked ? 0x80 : 0x00) | UInt8(length))
        } else if length <= 0xFFFF {
            frame.append((masked ? 0x80 : 0x00) | 126)
            frame.append(UInt8((length >> 8) & 0xFF))
            frame.append(UInt8(length & 0xFF))
        } else {
            frame.append((masked ? 0x80 : 0x00) | 127)
            let length64 = UInt64(length)
            for shift in stride(from: 56, through: 0, by: -8) {
                frame.append(UInt8((length64 >> UInt64(shift)) & 0xFF))
            }
        }

        if masked {
            let maskKey = randomBytes(count: 4)
            frame.append(contentsOf: maskKey)

            var maskedPayload = [UInt8](payload)
            for index in maskedPayload.indices {
                maskedPayload[index] ^= maskKey[index % 4]
            }
            frame.append(contentsOf: maskedPayload)
        } else {
            frame.append(payload)
        }

        return frame
    }

    private static func randomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        if status == errSecSuccess {
            return bytes
        }
        return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
    }

    private func handleInboundText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        guard let data = trimmed.data(using: .utf8),
              let envelope = try? decoder.decode(JSONRPCIncomingEnvelope.self, from: data) else {
            continuation?.yield(.stderr("malformed JSON-RPC message: \(trimmed)"))
            return
        }

        if let method = envelope.method {
            if let id = envelope.id {
                let request = AppServerRequestMessage(
                    id: id,
                    method: AppServerServerRequestMethod(method: method),
                    params: envelope.params
                )
                continuation?.yield(.request(request))
                return
            }

            let notification = AppServerNotificationMessage(
                method: AppServerNotificationMethod(method: method),
                params: envelope.params
            )
            continuation?.yield(.notification(notification))
            return
        }

        guard let id = envelope.id else {
            continuation?.yield(.stderr("malformed JSON-RPC message missing method/id."))
            return
        }

        guard let pending = pendingRequests.removeValue(forKey: id) else {
            return
        }

        if let error = envelope.error {
            pending.resume(throwing: CodexAppServerError.rpc(error))
            return
        }

        pending.resume(returning: envelope.result ?? .object([:]))
    }

    private func didTerminate(with status: Int32?) {
#if os(macOS)
        process = nil
        stdinHandle = nil

        stdoutTask?.cancel()
        stdoutTask = nil

        stderrTask?.cancel()
        stderrTask = nil
#endif

        webSocketReaderTask?.cancel()
        webSocketReaderTask = nil

        webSocketConnection?.cancel()
        webSocketConnection = nil
        webSocketInboundBuffer.removeAll(keepingCapacity: true)
        webSocketTextFragmentBuffer.removeAll(keepingCapacity: true)

        failPendingRequests(with: CodexAppServerError.terminated(status ?? -1))
        continuation?.yield(.disconnected(exitCode: status))
    }

    private func failPendingRequests(with error: Error) {
        let pending = pendingRequests
        pendingRequests.removeAll()

        for (_, continuation) in pending {
            continuation.resume(throwing: error)
        }
    }
}
