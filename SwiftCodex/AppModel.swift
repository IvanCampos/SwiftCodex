//
//  AppModel.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import SwiftUI
import CodexAppServerSDK

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

    var selectedEndpoint: AppServerMethod?
    var logs: [EndpointLogEntry] = []
    var logsNewestFirst: [EndpointLogEntry] = []
    var activeThreadID: String?
    var activeTurnID: String?
    var lastResponseWasSuccess: Bool?
    var lastResponseWasWarning = false
    var lastResponseRevision = 0
    var responseGuidanceMessage: String?

    private let maxLogCount = 300
    private var logByID: [EndpointLogEntry.ID: EndpointLogEntry] = [:]

    @ObservationIgnored
    private let endpointSession: EndpointSessionService

    init() {
        endpointSession = EndpointSessionService(webSocketURL: Self.defaultWebSocketURL)
        endpointSession.onInboundMessage = { [weak self] message in
            self?.handleInboundMessage(message)
        }
    }

    var webSocketURL: String {
        get { endpointSession.webSocketURL }
        set { endpointSession.webSocketURL = newValue }
    }

    var connectionState: EndpointConnectionState {
        endpointSession.connectionState
    }

    var isInitialized: Bool {
        endpointSession.isInitialized
    }

    var lastRequestJSON: String {
        get { endpointSession.lastRequestJSON }
        set { endpointSession.lastRequestJSON = newValue }
    }

    var lastResponseJSON: String {
        get { endpointSession.lastResponseJSON }
        set { endpointSession.lastResponseJSON = newValue }
    }

    var isEndpointConnected: Bool {
        endpointSession.isConnected
    }

    func connectEndpointWebSocket() async {
        if endpointSession.isConnected {
            appendLifecycleLog("Disconnected from app-server.")
        }

        await endpointSession.connect()

        switch endpointSession.connectionState {
        case .connected:
            appendLifecycleLog("Connected to \(endpointSession.webSocketURL).")
        case .failed(let message):
            appendLifecycleLog("Connect failed: \(message)")
        default:
            break
        }
    }

    func disconnectEndpointClient() {
        if endpointSession.isConnected {
            appendLifecycleLog("Disconnected from app-server.")
        }

        endpointSession.disconnect()
    }

    func clearEndpointLogs() {
        logs.removeAll()
        logsNewestFirst.removeAll()
        logByID.removeAll()
        lastRequestJSON = ""
        lastResponseJSON = ""
        lastResponseWasSuccess = nil
        lastResponseWasWarning = false
        lastResponseRevision = 0
        responseGuidanceMessage = nil
        selectedEndpoint = nil
    }

    func invokeEndpoint(_ method: AppServerMethod) async {
        selectedEndpoint = method

        let params = EndpointRequestFactory.makeParams(
            for: method,
            activeThreadID: activeThreadID,
            activeTurnID: activeTurnID
        )
        let invocation = await endpointSession.invoke(method: method, params: params)
        lastResponseWasSuccess = invocation.success
        lastResponseRevision &+= 1
        let responseGuidance = guidance(for: invocation)
        lastResponseWasWarning = responseGuidance.isWarning
        responseGuidanceMessage = responseGuidance.message

        if let result = invocation.result {
            syncTrackingIDs(from: method, result: result)
        }

        appendLog(
            EndpointLogEntry(
                timestamp: Date(),
                kind: .requestResponse,
                method: invocation.method,
                requestJSON: invocation.requestJSON,
                responseJSON: invocation.responseJSON,
                success: invocation.success,
                latencyMs: invocation.latencyMs,
                errorCode: invocation.errorCode,
                errorMessage: invocation.errorMessage
            )
        )
    }

    func logEntry(id: EndpointLogEntry.ID?) -> EndpointLogEntry? {
        guard let id else { return nil }
        return logByID[id]
    }

    private func handleInboundMessage(_ message: AppServerInboundMessage) {
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
        logsNewestFirst.insert(entry, at: 0)
        logByID[entry.id] = entry

        if logs.count > maxLogCount {
            let overflow = logs.count - maxLogCount
            let removedEntries = logs.prefix(overflow)
            logs.removeFirst(overflow)
            logsNewestFirst.removeLast(min(overflow, logsNewestFirst.count))

            for removedEntry in removedEntries {
                logByID.removeValue(forKey: removedEntry.id)
            }
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

    private func guidance(for invocation: EndpointInvocationResult) -> (message: String?, isWarning: Bool) {
        guard invocation.success == false else { return (nil, false) }

        let candidates = [
            invocation.errorMessage,
            extractErrorMessage(from: invocation.responseJSON)
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        for message in candidates {
            let normalized = message.lowercased()

            if normalized.contains("not connected to app-server") || normalized == "not connected." {
                return ("You are not connected to the app-server. Enter a server URL and tap Connect.", false)
            }

            if invocation.method == AppServerMethod.skillsRemoteList.rawValue
                && (normalized.contains("failed to list remote skills")
                    || (normalized.contains("status 403 forbidden") && normalized.contains("notallowed"))) {
                return ("Remote skills are blocked for the current account/session (403 NotAllowed). Sign in with an account that has remote-skills access, or use skills/list for local skills.", false)
            }

            if normalized.contains("already initialized") {
                return ("This can be ignored, as initialize endpoint has already been called.", true)
            }

            if normalized.contains("not initialized") {
                return ("The server is not initialized. Call the initialize endpoint first.", false)
            }
        }

        return (nil, false)
    }

    private func extractErrorMessage(from responseJSON: String) -> String? {
        guard let data = responseJSON.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errorNode = jsonObject["error"] else {
            return nil
        }

        if let errorString = errorNode as? String {
            return errorString
        }

        if let errorObject = errorNode as? [String: Any],
           let message = errorObject["message"] as? String {
            return message
        }

        return nil
    }
}
