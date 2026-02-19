//
//  AppModel.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    static let defaultWebSocketURL: String = {
#if targetEnvironment(simulator)
        return "ws://127.0.0.1:4500"
#else
        return "ws://10.0.0.8:4500"
#endif
    }()

    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    var webSocketURL = defaultWebSocketURL
    var connectionState: EndpointConnectionState = .disconnected
    var isInitialized = false
    var selectedEndpoint: AppServerMethod?
    var lastRequestJSON = ""
    var lastResponseJSON = ""
    var logs: [EndpointLogEntry] = []
    var activeThreadID: String?
    var activeTurnID: String?

    private var endpointClient: CodexAppServerClient?
    private var inboundListenerTask: Task<Void, Never>?

    var isEndpointConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }

    func connectEndpointWebSocket() async {
        disconnectEndpointClient()
        connectionState = .connecting

        guard let url = URL(string: webSocketURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss" else {
            connectionState = .failed("Invalid websocket URL.")
            appendLifecycleLog("Connect failed: invalid websocket URL '\(webSocketURL)'.")
            return
        }

        let client = CodexAppServerClient()

        do {
            try await client.connectWebSocket(url: url)
            endpointClient = client
            connectionState = .connected
            isInitialized = false
            appendLifecycleLog("Connected to \(webSocketURL).")
            startInboundListener(for: client)
        } catch {
            endpointClient = nil
            let (_, message, _) = formattedErrorPayload(error)
            connectionState = .failed(message)
            appendLifecycleLog("Connect failed: \(message)")
        }
    }

    func disconnectEndpointClient() {
        inboundListenerTask?.cancel()
        inboundListenerTask = nil

        endpointClient?.disconnect()
        endpointClient = nil

        if case .connected = connectionState {
            appendLifecycleLog("Disconnected from app-server.")
        }

        connectionState = .disconnected
        isInitialized = false
    }

    func clearEndpointLogs() {
        logs.removeAll()
        lastRequestJSON = ""
        lastResponseJSON = ""
        selectedEndpoint = nil
    }

    func invokeEndpoint(_ method: AppServerMethod) async {
        selectedEndpoint = method

        let params = EndpointRequestFactory.makeParams(
            for: method,
            activeThreadID: activeThreadID,
            activeTurnID: activeTurnID
        )
        let requestJSON = EndpointJSONFormatter.requestJSON(method: method.rawValue, params: params)
        lastRequestJSON = requestJSON

        guard let endpointClient else {
            let notConnected = EndpointJSONFormatter.genericErrorJSON("Not connected to app-server.")
            lastResponseJSON = notConnected
            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .requestResponse,
                    method: method.rawValue,
                    requestJSON: requestJSON,
                    responseJSON: notConnected,
                    success: false,
                    latencyMs: nil,
                    errorCode: nil,
                    errorMessage: "Not connected."
                )
            )
            return
        }

        let startedAt = Date()

        do {
            let result = try await endpointClient.callRaw(method: method.rawValue, params: params)
            var initializedNotificationSent = false

            if method == .initialize {
                try endpointClient.sendNotification(method: "initialized")
                isInitialized = true
                initializedNotificationSent = true
            }

            syncTrackingIDs(from: method, result: result)

            let responseJSON = EndpointJSONFormatter.responseJSON(
                result: result,
                initializationAcknowledged: initializedNotificationSent
            )
            lastResponseJSON = responseJSON

            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .requestResponse,
                    method: method.rawValue,
                    requestJSON: requestJSON,
                    responseJSON: responseJSON,
                    success: true,
                    latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000),
                    errorCode: nil,
                    errorMessage: nil
                )
            )
        } catch {
            let (errorCode, errorMessage, errorJSON) = formattedErrorPayload(error)
            lastResponseJSON = errorJSON

            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .requestResponse,
                    method: method.rawValue,
                    requestJSON: requestJSON,
                    responseJSON: errorJSON,
                    success: false,
                    latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000),
                    errorCode: errorCode,
                    errorMessage: errorMessage
                )
            )
        }
    }

    private func startInboundListener(for client: CodexAppServerClient) {
        inboundListenerTask?.cancel()
        inboundListenerTask = Task { [weak self] in
            guard let self else { return }

            for await inboundMessage in client.inboundMessages {
                self.handleInboundMessage(inboundMessage, from: client)
            }
        }
    }

    private func handleInboundMessage(_ message: AppServerInboundMessage, from sourceClient: CodexAppServerClient) {
        guard endpointClient === sourceClient else {
            return
        }

        switch message {
        case .notification(let notification):
            let payload = EndpointJSONFormatter.pretty(notification.params ?? .object([:]))
            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .notification,
                    method: notification.method.rawValue,
                    requestJSON: "",
                    responseJSON: payload,
                    success: true,
                    latencyMs: nil,
                    errorCode: nil,
                    errorMessage: nil
                )
            )
        case .request(let request):
            let payload = EndpointJSONFormatter.pretty(request.params ?? .object([:]))
            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .serverRequest,
                    method: request.method.rawValue,
                    requestJSON: "",
                    responseJSON: payload,
                    success: true,
                    latencyMs: nil,
                    errorCode: nil,
                    errorMessage: nil
                )
            )
        case .stderr(let line):
            appendLog(
                EndpointLogEntry(
                    timestamp: Date(),
                    kind: .stderr,
                    method: "stderr",
                    requestJSON: "",
                    responseJSON: line,
                    success: false,
                    latencyMs: nil,
                    errorCode: nil,
                    errorMessage: line
                )
            )
        case .disconnected(let exitCode):
            endpointClient = nil
            inboundListenerTask?.cancel()
            inboundListenerTask = nil
            connectionState = .disconnected
            isInitialized = false
            appendLifecycleLog("Connection closed (exit code: \(exitCode.map(String.init) ?? "n/a")).")
        }
    }

    private func appendLifecycleLog(_ message: String) {
        appendLog(
            EndpointLogEntry(
                timestamp: Date(),
                kind: .lifecycle,
                method: "lifecycle",
                requestJSON: "",
                responseJSON: message,
                success: true,
                latencyMs: nil,
                errorCode: nil,
                errorMessage: nil
            )
        )
    }

    private func appendLog(_ entry: EndpointLogEntry) {
        logs.append(entry)
        if logs.count > 300 {
            logs.removeFirst(logs.count - 300)
        }
    }

    private func syncTrackingIDs(from method: AppServerMethod, result: JSONValue) {
        guard let payload = result.objectValue else { return }

        if let threadID = payload["thread"]?.objectValue?["id"]?.stringValue {
            activeThreadID = threadID
        }

        if let turnID = payload["turn"]?.objectValue?["id"]?.stringValue {
            activeTurnID = turnID
        }

        if let turnID = payload["turnId"]?.stringValue {
            activeTurnID = turnID
        }

        if method == .reviewStart, let reviewThreadID = payload["reviewThreadId"]?.stringValue {
            activeThreadID = reviewThreadID
        }
    }

    private func formattedErrorPayload(_ error: Error) -> (Int?, String, String) {
        if let codexError = error as? CodexAppServerError {
            switch codexError {
            case .rpc(let rpcError):
                return (
                    rpcError.code,
                    rpcError.message,
                    EndpointJSONFormatter.rpcErrorJSON(
                        code: rpcError.code,
                        message: rpcError.message,
                        data: rpcError.data
                    )
                )
            case .unsupportedPlatform(let message):
                return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
            case .terminated(let code):
                let message = "Connection terminated (exit code: \(code))."
                return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
            case .invalidWebSocketURL(let message),
                 .websocketHandshakeFailed(let message),
                 .websocketProtocolViolation(let message):
                return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
            default:
                let message = String(describing: codexError)
                return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
            }
        }

        if let posixError = error as? POSIXError {
            if posixError.code == .ECONNREFUSED {
                let message = """
                Connection refused at \(webSocketURL). Start app-server first: codex app-server --listen ws://0.0.0.0:4500. \
                If running in Simulator on the same Mac, use ws://127.0.0.1:4500.
                """
                return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
            }
        }

        let message = error.localizedDescription
        return (nil, message, EndpointJSONFormatter.genericErrorJSON(message))
    }
}
