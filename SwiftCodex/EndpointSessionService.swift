//
//  EndpointSessionService.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/19/26.
//

import Foundation
import SwiftUI
import CodexAppServerSDK

struct EndpointInvocationResult {
    let method: String
    let requestJSON: String
    let responseJSON: String
    let success: Bool
    let latencyMs: Int?
    let errorCode: Int?
    let errorMessage: String?
    let result: JSONValue?
}

struct EndpointModelListInvocationResult {
    let invocation: EndpointInvocationResult
    let modelIDs: [String]
}

@MainActor
@Observable
final class EndpointSessionService {
    var webSocketURL: String
    var connectionState: EndpointConnectionState = .disconnected
    var isInitialized = false
    var lastRequestJSON = ""
    var lastResponseJSON = ""

    var onInboundMessage: ((AppServerInboundMessage) -> Void)?

    private var endpointClient: CodexAppServerClient?
    private var inboundListenerTask: Task<Void, Never>?

    init(webSocketURL: String) {
        self.webSocketURL = webSocketURL
    }

    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }

    func connect() async {
        disconnect()
        connectionState = .connecting

        guard let url = URL(string: webSocketURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss" else {
            connectionState = .failed("Invalid websocket URL.")
            lastResponseJSON = EndpointJSONFormatter.genericErrorJSON("Invalid websocket URL: \(webSocketURL)")
            return
        }

        let client = CodexAppServerClient()

        do {
            try await client.connectWebSocket(url: url)
            endpointClient = client
            connectionState = .connected
            isInitialized = false
            startInboundListener(for: client)
        } catch {
            endpointClient = nil
            let (_, message, errorJSON) = formattedErrorPayload(error)
            connectionState = .failed(message)
            lastResponseJSON = errorJSON
        }
    }

    func disconnect() {
        inboundListenerTask?.cancel()
        inboundListenerTask = nil

        endpointClient?.disconnect()
        endpointClient = nil

        connectionState = .disconnected
        isInitialized = false
    }

    func invoke(method: AppServerMethod, params: JSONValue?) async -> EndpointInvocationResult {
        let requestJSON = EndpointJSONFormatter.requestJSON(method: method.rawValue, params: params)
        lastRequestJSON = requestJSON

        guard let endpointClient else {
            let notConnected = EndpointJSONFormatter.genericErrorJSON("Not connected to app-server.")
            lastResponseJSON = notConnected
            return EndpointInvocationResult(
                method: method.rawValue,
                requestJSON: requestJSON,
                responseJSON: notConnected,
                success: false,
                latencyMs: nil,
                errorCode: nil,
                errorMessage: "Not connected.",
                result: nil
            )
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

            let responseJSON = EndpointJSONFormatter.responseJSON(
                result: result,
                initializationAcknowledged: initializedNotificationSent
            )
            lastResponseJSON = responseJSON

            return EndpointInvocationResult(
                method: method.rawValue,
                requestJSON: requestJSON,
                responseJSON: responseJSON,
                success: true,
                latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000),
                errorCode: nil,
                errorMessage: nil,
                result: result
            )
        } catch {
            let (errorCode, errorMessage, errorJSON) = formattedErrorPayload(error)
            lastResponseJSON = errorJSON

            return EndpointInvocationResult(
                method: method.rawValue,
                requestJSON: requestJSON,
                responseJSON: errorJSON,
                success: false,
                latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000),
                errorCode: errorCode,
                errorMessage: errorMessage,
                result: nil
            )
        }
    }

    func invokeInitialize(
        clientInfo: ClientInfo,
        capabilities: ClientCapabilities?
    ) async -> EndpointInvocationResult {
        let params = InitializeParams(clientInfo: clientInfo, capabilities: capabilities)

        do {
            let payload = try JSONValueCoding.encode(params)
            return await invoke(method: .initialize, params: payload)
        } catch {
            let method = AppServerMethod.initialize.rawValue
            let requestJSON = EndpointJSONFormatter.requestJSON(method: method, params: nil)
            let message = "Failed to encode initialize params: \(error.localizedDescription)"
            let responseJSON = EndpointJSONFormatter.genericErrorJSON(message)

            lastRequestJSON = requestJSON
            lastResponseJSON = responseJSON

            return EndpointInvocationResult(
                method: method,
                requestJSON: requestJSON,
                responseJSON: responseJSON,
                success: false,
                latencyMs: nil,
                errorCode: nil,
                errorMessage: message,
                result: nil
            )
        }
    }

    func invokeModelList(includeHidden: Bool = true) async -> EndpointModelListInvocationResult {
        let params = ModelListParams(includeHidden: includeHidden)

        do {
            let payload = try JSONValueCoding.encode(params)
            let invocation = await invoke(method: .modelList, params: payload)

            guard invocation.success, let result = invocation.result else {
                return EndpointModelListInvocationResult(invocation: invocation, modelIDs: [])
            }

            let modelIDs = modelIDs(from: result)
            return EndpointModelListInvocationResult(invocation: invocation, modelIDs: modelIDs)
        } catch {
            let method = AppServerMethod.modelList.rawValue
            let requestJSON = EndpointJSONFormatter.requestJSON(method: method, params: nil)
            let message = "Failed to encode model/list params: \(error.localizedDescription)"
            let responseJSON = EndpointJSONFormatter.genericErrorJSON(message)

            lastRequestJSON = requestJSON
            lastResponseJSON = responseJSON

            let invocation = EndpointInvocationResult(
                method: method,
                requestJSON: requestJSON,
                responseJSON: responseJSON,
                success: false,
                latencyMs: nil,
                errorCode: nil,
                errorMessage: message,
                result: nil
            )
            return EndpointModelListInvocationResult(invocation: invocation, modelIDs: [])
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

        if case .disconnected = message {
            endpointClient = nil
            inboundListenerTask?.cancel()
            inboundListenerTask = nil
            connectionState = .disconnected
            isInitialized = false
        }

        onInboundMessage?(message)
    }

    private func modelIDs(from result: JSONValue) -> [String] {
        guard let payload = result.objectValue,
              let modelEntries = payload["data"]?.arrayValue else {
            return []
        }

        return modelEntries.compactMap { entry in
            entry.objectValue?["id"]?.stringValue
        }.sorted()
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
