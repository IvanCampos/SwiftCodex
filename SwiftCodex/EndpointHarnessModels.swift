//
//  EndpointHarnessModels.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import Foundation
import CodexAppServerSDK

enum EndpointConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

enum EndpointLogKind: String {
    case requestResponse = "call"
    case notification = "notification"
    case serverRequest = "server-request"
    case stderr = "stderr"
    case lifecycle = "lifecycle"
}

struct EndpointLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let kind: EndpointLogKind
    let method: String
    let requestJSON: String
    let responseJSON: String
    let success: Bool
    let latencyMs: Int?
    let errorCode: Int?
    let errorMessage: String?
}

enum EndpointJSONFormatter {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static func requestJSON(method: String, params: JSONValue?) -> String {
        var payload: [String: JSONValue] = [
            "method": .string(method)
        ]

        if let params {
            payload["params"] = params
        }

        return pretty(.object(payload))
    }

    static func responseJSON(result: JSONValue, initializationAcknowledged: Bool = false) -> String {
        var payload: [String: JSONValue] = [
            "result": result
        ]

        if initializationAcknowledged {
            payload["initializedNotificationSent"] = .bool(true)
        }

        return pretty(.object(payload))
    }

    static func rpcErrorJSON(code: Int, message: String, data: JSONValue?) -> String {
        var errorPayload: [String: JSONValue] = [
            "code": .number(Double(code)),
            "message": .string(message)
        ]

        if let data {
            errorPayload["data"] = data
        }

        return pretty(.object(["error": .object(errorPayload)]))
    }

    static func genericErrorJSON(_ message: String) -> String {
        pretty(.object(["error": .string(message)]))
    }

    static func pretty(_ value: JSONValue) -> String {
        do {
            let data = try encoder.encode(value)
            return String(decoding: data, as: UTF8.self)
        } catch {
            return String(describing: value)
        }
    }
}

enum EndpointMethodCatalog {
    static let apiOverviewURLString = "https://developers.openai.com/codex/app-server/#api-overview"

    static func description(for method: AppServerMethod) -> String? {
        switch method {
        case .initialize:
            return "Initialize once per connection, then send the initialized notification before invoking other methods."
        case .threadStart:
            return "Create a new thread and subscribe to turn/item events for that thread."
        case .threadResume:
            return "Reopen an existing thread by id so later turns continue in that thread."
        case .threadFork:
            return "Fork an existing thread into a new thread id using copied history."
        case .threadList:
            return "List stored thread logs with cursor pagination and optional filters."
        case .threadLoadedList:
            return "List thread ids currently loaded in memory."
        case .threadRead:
            return "Read a stored thread by id without resuming it."
        case .threadArchive:
            return "Archive a thread by moving its log into the archived directory."
        case .threadNameSet:
            return "Set or rename a thread's display name."
        case .threadUnarchive:
            return "Restore an archived thread back to active sessions."
        case .threadCompactStart:
            return "Start server-side compaction and create a compacted child thread."
        case .threadBackgroundTerminalsClean:
            return "Terminate and reap completed background terminal commands for a thread."
        case .threadRollback:
            return "Rollback the latest turn and related trailing user messages from a thread."
        case .turnStart:
            return "Start a new turn in a thread with user input."
        case .turnSteer:
            return "Append additional user input to an in-flight turn."
        case .turnInterrupt:
            return "Request cancellation of a running turn."
        case .reviewStart:
            return "Run a review against a target and return review results."
        case .commandExec:
            return "Execute one shell command and return stdout, stderr, and exit code."
        case .modelList:
            return "List models available to the current account/provider configuration."
        case .experimentalFeatureList:
            return "List experimental features and their enabled state."
        case .collaborationModeList:
            return "List collaboration mode presets."
        case .skillsList:
            return "List skills for one or more working directories."
        case .skillsRemoteList:
            return nil
        case .skillsRemoteExport:
            return nil
        case .appList:
            return "List available apps/connectors with pagination and accessibility metadata."
        case .skillsConfigWrite:
            return "Enable or disable a skill by file path."
        case .mcpServerOAuthLogin:
            return "Start OAuth login for a configured MCP server."
        case .toolRequestUserInput:
            return "Prompt the user with short questions for an approval/tool-input flow."
        case .configMCPServerReload:
            return "Reload MCP server configuration from disk and refresh loaded threads."
        case .mcpServerStatusList:
            return "List MCP servers, tools/resources, and auth status."
        case .windowsSandboxSetupStart:
            return nil
        case .feedbackUpload:
            return "Upload a feedback report with classification and optional context."
        case .configRead:
            return "Read the effective configuration after applying config layering."
        case .configValueWrite:
            return "Write a single configuration key/value to user config."
        case .configBatchWrite:
            return "Apply multiple configuration edits atomically."
        case .configRequirementsRead:
            return "Read requirements from requirements.toml and/or MDM policies."
        case .accountRead:
            return "Read current account/auth state and optionally refresh tokens."
        case .accountLoginStart:
            return "Start login for apiKey, chatgpt, or externally managed ChatGPT tokens."
        case .accountLoginCancel:
            return "Cancel a pending ChatGPT login by login id."
        case .accountLogout:
            return "Log out and clear active auth mode."
        case .accountRateLimitsRead:
            return "Read ChatGPT account rate limits."
        }
    }
}

enum EndpointRequestFactory {
    static func makeParams(for method: AppServerMethod, activeThreadID: String?, activeTurnID: String?) -> JSONValue? {
        let threadID = activeThreadID ?? "thr_test_missing"
        let turnID = activeTurnID ?? "turn_test_missing"

        switch method {
        case .initialize:
            return .object([
                "clientInfo": .object([
                    "name": .string("swiftcodex_visionos"),
                    "title": .string("SwiftCodex Endpoint Harness"),
                    "version": .string("0.1.0")
                ]),
                "capabilities": .object([
                    "experimentalApi": .bool(true)
                ])
            ])
        case .threadStart:
            return .object([
                "approvalPolicy": .string("never"),
                "sandbox": .string("workspaceWrite"),
                "personality": .string("pragmatic")
            ])
        case .threadResume:
            return .object([
                "threadId": .string(threadID),
                "personality": .string("pragmatic")
            ])
        case .threadFork:
            return .object([
                "threadId": .string(threadID)
            ])
        case .threadList:
            return .object([
                "cursor": .null,
                "limit": .number(25),
                "sortKey": .string("created_at")
            ])
        case .threadLoadedList:
            return .object([:])
        case .threadRead:
            return .object([
                "threadId": .string(threadID),
                "includeTurns": .bool(true)
            ])
        case .threadArchive:
            return .object([
                "threadId": .string(threadID)
            ])
        case .threadNameSet:
            return .object([
                "threadId": .string(threadID),
                "name": .string("SwiftCodex Endpoint Harness Thread")
            ])
        case .threadUnarchive:
            return .object([
                "threadId": .string(threadID)
            ])
        case .threadCompactStart:
            return .object([
                "threadId": .string(threadID)
            ])
        case .threadBackgroundTerminalsClean:
            return .object([
                "threadId": .string(threadID)
            ])
        case .threadRollback:
            return .object([
                "threadId": .string(threadID),
                "numTurns": .number(1)
            ])
        case .turnStart:
            return .object([
                "threadId": .string(threadID),
                "input": .array([
                    .object([
                        "type": .string("text"),
                        "text": .string("Test request from SwiftCodex UI.")
                    ])
                ])
            ])
        case .turnSteer:
            return .object([
                "threadId": .string(threadID),
                "expectedTurnId": .string(turnID),
                "input": .array([
                    .object([
                        "type": .string("text"),
                        "text": .string("Steer test request from SwiftCodex UI.")
                    ])
                ])
            ])
        case .turnInterrupt:
            return .object([
                "threadId": .string(threadID),
                "turnId": .string(turnID)
            ])
        case .reviewStart:
            return .object([
                "threadId": .string(threadID),
                "delivery": .string("inline"),
                "target": .object([
                    "type": .string("uncommittedChanges")
                ])
            ])
        case .commandExec:
            return .object([
                "command": .array([.string("echo"), .string("swiftcodex-endpoint-test")]),
                "timeoutMs": .number(5000)
            ])
        case .modelList:
            return .object([
                "includeHidden": .bool(true)
            ])
        case .experimentalFeatureList:
            return .object([
                "cursor": .null,
                "limit": .number(50)
            ])
        case .collaborationModeList:
            return .object([:])
        case .skillsList:
            return .object([
                "forceReload": .bool(false)
            ])
        case .skillsRemoteList:
            return .object([
                "cursor": .null,
                "limit": .number(25)
            ])
        case .skillsRemoteExport:
            return .object([
                "hazelnutId": .string("test-skill-id")
            ])
        case .appList:
            return .object([
                "cursor": .null,
                "limit": .number(50),
                "forceRefetch": .bool(false)
            ])
        case .skillsConfigWrite:
            return .object([
                "path": .string("/tmp/skill/SKILL.md"),
                "enabled": .bool(false)
            ])
        case .mcpServerOAuthLogin:
            return .object([
                "name": .string("test-server")
            ])
        case .toolRequestUserInput:
            return .object([
                "questions": .array([
                    .object([
                        "header": .string("Test"),
                        "id": .string("test_id"),
                        "question": .string("Pick one"),
                        "options": .array([
                            .object([
                                "label": .string("Yes"),
                                "description": .string("Test option")
                            ])
                        ])
                    ])
                ])
            ])
        case .configMCPServerReload:
            return nil
        case .mcpServerStatusList:
            return .object([
                "cursor": .null,
                "limit": .number(50)
            ])
        case .windowsSandboxSetupStart:
            return .object([
                "mode": .string("unelevated")
            ])
        case .feedbackUpload:
            return .object([
                "classification": .string("other"),
                "reason": .string("UI endpoint harness test")
            ])
        case .configRead:
            return .object([:])
        case .configValueWrite:
            return .object([
                "key": .string("model"),
                "value": .string("gpt-5.1-codex")
            ])
        case .configBatchWrite:
            return .object([
                "edits": .array([
                    .object([
                        "key": .string("model"),
                        "value": .string("gpt-5.1-codex")
                    ])
                ])
            ])
        case .configRequirementsRead:
            return nil
        case .accountRead:
            return .object([
                "refreshToken": .bool(false)
            ])
        case .accountLoginStart:
            return .object([
                "type": .string("chatgpt")
            ])
        case .accountLoginCancel:
            return .object([
                "loginId": .string("00000000-0000-0000-0000-000000000000")
            ])
        case .accountLogout:
            return nil
        case .accountRateLimitsRead:
            return nil
        }
    }
}
