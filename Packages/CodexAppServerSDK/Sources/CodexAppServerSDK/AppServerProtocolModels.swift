import Foundation

public enum AppServerMethod: String, CaseIterable, Sendable {
    case initialize = "initialize"
    case threadStart = "thread/start"
    case threadResume = "thread/resume"
    case threadFork = "thread/fork"
    case threadList = "thread/list"
    case threadLoadedList = "thread/loaded/list"
    case threadRead = "thread/read"
    case threadArchive = "thread/archive"
    case threadNameSet = "thread/name/set"
    case threadUnarchive = "thread/unarchive"
    case threadCompactStart = "thread/compact/start"
    case threadBackgroundTerminalsClean = "thread/backgroundTerminals/clean"
    case threadRollback = "thread/rollback"
    case turnStart = "turn/start"
    case turnSteer = "turn/steer"
    case turnInterrupt = "turn/interrupt"
    case reviewStart = "review/start"
    case commandExec = "command/exec"
    case modelList = "model/list"
    case experimentalFeatureList = "experimentalFeature/list"
    case collaborationModeList = "collaborationMode/list"
    case skillsList = "skills/list"
    case skillsRemoteList = "skills/remote/list"
    case skillsRemoteExport = "skills/remote/export"
    case appList = "app/list"
    case skillsConfigWrite = "skills/config/write"
    case mcpServerOAuthLogin = "mcpServer/oauth/login"
    case toolRequestUserInput = "tool/requestUserInput"
    case configMCPServerReload = "config/mcpServer/reload"
    case mcpServerStatusList = "mcpServerStatus/list"
    case windowsSandboxSetupStart = "windowsSandbox/setupStart"
    case feedbackUpload = "feedback/upload"
    case configRead = "config/read"
    case configValueWrite = "config/value/write"
    case configBatchWrite = "config/batchWrite"
    case configRequirementsRead = "configRequirements/read"
    case accountRead = "account/read"
    case accountLoginStart = "account/login/start"
    case accountLoginCancel = "account/login/cancel"
    case accountLogout = "account/logout"
    case accountRateLimitsRead = "account/rateLimits/read"
}

public enum AppServerNotificationMethod: Hashable, Sendable {
    case threadStarted
    case threadArchived
    case threadUnarchived
    case threadStatusChanged
    case threadTokenUsageUpdated
    case turnStarted
    case turnCompleted
    case turnDiffUpdated
    case turnPlanUpdated
    case modelRerouted
    case itemStarted
    case itemCompleted
    case itemAgentMessageDelta
    case itemPlanDelta
    case itemReasoningSummaryTextDelta
    case itemReasoningSummaryPartAdded
    case itemReasoningTextDelta
    case itemCommandExecutionOutputDelta
    case itemFileChangeOutputDelta
    case error
    case appListUpdated
    case mcpServerOAuthLoginCompleted
    case accountLoginCompleted
    case accountUpdated
    case accountRateLimitsUpdated
    case fuzzyFileSearchSessionUpdated
    case fuzzyFileSearchSessionCompleted
    case windowsSandboxSetupCompleted
    case codexEventSessionConfigured
    case unknown(String)

    public init(method: String) {
        switch method {
        case "thread/started":
            self = .threadStarted
        case "thread/archived":
            self = .threadArchived
        case "thread/unarchived":
            self = .threadUnarchived
        case "thread/status/changed":
            self = .threadStatusChanged
        case "thread/tokenUsage/updated":
            self = .threadTokenUsageUpdated
        case "turn/started":
            self = .turnStarted
        case "turn/completed":
            self = .turnCompleted
        case "turn/diff/updated":
            self = .turnDiffUpdated
        case "turn/plan/updated":
            self = .turnPlanUpdated
        case "model/rerouted":
            self = .modelRerouted
        case "item/started":
            self = .itemStarted
        case "item/completed":
            self = .itemCompleted
        case "item/agentMessage/delta":
            self = .itemAgentMessageDelta
        case "item/plan/delta":
            self = .itemPlanDelta
        case "item/reasoning/summaryTextDelta":
            self = .itemReasoningSummaryTextDelta
        case "item/reasoning/summaryPartAdded":
            self = .itemReasoningSummaryPartAdded
        case "item/reasoning/textDelta":
            self = .itemReasoningTextDelta
        case "item/commandExecution/outputDelta":
            self = .itemCommandExecutionOutputDelta
        case "item/fileChange/outputDelta":
            self = .itemFileChangeOutputDelta
        case "error":
            self = .error
        case "app/list/updated":
            self = .appListUpdated
        case "mcpServer/oauthLogin/completed":
            self = .mcpServerOAuthLoginCompleted
        case "account/login/completed":
            self = .accountLoginCompleted
        case "account/updated":
            self = .accountUpdated
        case "account/rateLimits/updated":
            self = .accountRateLimitsUpdated
        case "fuzzyFileSearch/sessionUpdated":
            self = .fuzzyFileSearchSessionUpdated
        case "fuzzyFileSearch/sessionCompleted":
            self = .fuzzyFileSearchSessionCompleted
        case "windowsSandbox/setupCompleted":
            self = .windowsSandboxSetupCompleted
        case "codex/event/session_configured":
            self = .codexEventSessionConfigured
        default:
            self = .unknown(method)
        }
    }

    public var rawValue: String {
        switch self {
        case .threadStarted:
            return "thread/started"
        case .threadArchived:
            return "thread/archived"
        case .threadUnarchived:
            return "thread/unarchived"
        case .threadStatusChanged:
            return "thread/status/changed"
        case .threadTokenUsageUpdated:
            return "thread/tokenUsage/updated"
        case .turnStarted:
            return "turn/started"
        case .turnCompleted:
            return "turn/completed"
        case .turnDiffUpdated:
            return "turn/diff/updated"
        case .turnPlanUpdated:
            return "turn/plan/updated"
        case .modelRerouted:
            return "model/rerouted"
        case .itemStarted:
            return "item/started"
        case .itemCompleted:
            return "item/completed"
        case .itemAgentMessageDelta:
            return "item/agentMessage/delta"
        case .itemPlanDelta:
            return "item/plan/delta"
        case .itemReasoningSummaryTextDelta:
            return "item/reasoning/summaryTextDelta"
        case .itemReasoningSummaryPartAdded:
            return "item/reasoning/summaryPartAdded"
        case .itemReasoningTextDelta:
            return "item/reasoning/textDelta"
        case .itemCommandExecutionOutputDelta:
            return "item/commandExecution/outputDelta"
        case .itemFileChangeOutputDelta:
            return "item/fileChange/outputDelta"
        case .error:
            return "error"
        case .appListUpdated:
            return "app/list/updated"
        case .mcpServerOAuthLoginCompleted:
            return "mcpServer/oauthLogin/completed"
        case .accountLoginCompleted:
            return "account/login/completed"
        case .accountUpdated:
            return "account/updated"
        case .accountRateLimitsUpdated:
            return "account/rateLimits/updated"
        case .fuzzyFileSearchSessionUpdated:
            return "fuzzyFileSearch/sessionUpdated"
        case .fuzzyFileSearchSessionCompleted:
            return "fuzzyFileSearch/sessionCompleted"
        case .windowsSandboxSetupCompleted:
            return "windowsSandbox/setupCompleted"
        case .codexEventSessionConfigured:
            return "codex/event/session_configured"
        case .unknown(let method):
            return method
        }
    }
}

public enum AppServerServerRequestMethod: Hashable, Sendable {
    case commandExecutionRequestApproval
    case fileChangeRequestApproval
    case toolCall
    case unknown(String)

    public init(method: String) {
        switch method {
        case "item/commandExecution/requestApproval":
            self = .commandExecutionRequestApproval
        case "item/fileChange/requestApproval":
            self = .fileChangeRequestApproval
        case "item/tool/call":
            self = .toolCall
        default:
            self = .unknown(method)
        }
    }

    public var rawValue: String {
        switch self {
        case .commandExecutionRequestApproval:
            return "item/commandExecution/requestApproval"
        case .fileChangeRequestApproval:
            return "item/fileChange/requestApproval"
        case .toolCall:
            return "item/tool/call"
        case .unknown(let method):
            return method
        }
    }
}

public struct AppServerNotificationMessage: Sendable {
    public let method: AppServerNotificationMethod
    public let params: JSONValue?

    public init(method: AppServerNotificationMethod, params: JSONValue?) {
        self.method = method
        self.params = params
    }

    public func decodeParams<T: Decodable>(_ type: T.Type) throws -> T {
        let value = params ?? .object([:])
        return try JSONValueCoding.decode(type, from: value)
    }
}

public struct AppServerRequestMessage: Sendable {
    public let id: JSONRPCID
    public let method: AppServerServerRequestMethod
    public let params: JSONValue?

    public init(id: JSONRPCID, method: AppServerServerRequestMethod, params: JSONValue?) {
        self.id = id
        self.method = method
        self.params = params
    }

    public func decodeParams<T: Decodable>(_ type: T.Type) throws -> T {
        let value = params ?? .object([:])
        return try JSONValueCoding.decode(type, from: value)
    }
}

public enum AppServerInboundMessage: Sendable {
    case notification(AppServerNotificationMessage)
    case request(AppServerRequestMessage)
    case stderr(String)
    case disconnected(exitCode: Int32?)
}

public struct InitializeParams: Codable, Sendable {
    public var clientInfo: ClientInfo
    public var capabilities: ClientCapabilities?

    public init(clientInfo: ClientInfo, capabilities: ClientCapabilities? = nil) {
        self.clientInfo = clientInfo
        self.capabilities = capabilities
    }
}

public struct ClientInfo: Codable, Sendable {
    public var name: String
    public var title: String?
    public var version: String?

    public init(name: String, title: String? = nil, version: String? = nil) {
        self.name = name
        self.title = title
        self.version = version
    }
}

public struct ClientCapabilities: Codable, Sendable {
    public var experimentalApi: Bool?
    public var optOutNotificationMethods: [String]?

    public init(experimentalApi: Bool? = nil, optOutNotificationMethods: [String]? = nil) {
        self.experimentalApi = experimentalApi
        self.optOutNotificationMethods = optOutNotificationMethods
    }
}

public struct InitializeResult: Codable, Sendable {
    public var userAgent: String?
}

public struct ThreadEnvelope: Codable, Sendable {
    public var thread: Thread

    public init(thread: Thread) {
        self.thread = thread
    }
}

public struct TurnEnvelope: Codable, Sendable {
    public var turn: Turn

    public init(turn: Turn) {
        self.turn = turn
    }
}

public struct TurnIDEnvelope: Codable, Sendable {
    public var turnId: String

    public init(turnId: String) {
        self.turnId = turnId
    }
}

public struct ReviewStartResult: Codable, Sendable {
    public var turn: Turn
    public var reviewThreadId: String

    public init(turn: Turn, reviewThreadId: String) {
        self.turn = turn
        self.reviewThreadId = reviewThreadId
    }
}

public struct ThreadListResult: Codable, Sendable {
    public var data: [Thread]
    public var nextCursor: String?

    public init(data: [Thread], nextCursor: String?) {
        self.data = data
        self.nextCursor = nextCursor
    }
}

public struct StringListResult: Codable, Sendable {
    public var data: [String]

    public init(data: [String]) {
        self.data = data
    }
}

public struct ModelListResult: Codable, Sendable {
    public var data: [ModelInfo]
    public var nextCursor: String?

    public init(data: [ModelInfo], nextCursor: String?) {
        self.data = data
        self.nextCursor = nextCursor
    }
}

public struct ExperimentalFeatureListResult: Codable, Sendable {
    public var data: [ExperimentalFeature]
    public var nextCursor: String?

    public init(data: [ExperimentalFeature], nextCursor: String?) {
        self.data = data
        self.nextCursor = nextCursor
    }
}

public struct CollaborationModeListResult: Codable, Sendable {
    public var data: [CollaborationMode]

    public init(data: [CollaborationMode]) {
        self.data = data
    }
}

public struct SkillsListResult: Codable, Sendable {
    public var data: [SkillsByCWD]

    public init(data: [SkillsByCWD]) {
        self.data = data
    }
}

public struct AppListResult: Codable, Sendable {
    public var data: [AppInfo]
    public var nextCursor: String?

    public init(data: [AppInfo], nextCursor: String?) {
        self.data = data
        self.nextCursor = nextCursor
    }
}

public struct MCPServerStatusListResult: Codable, Sendable {
    public var data: [MCPServerStatus]
    public var nextCursor: String?

    public init(data: [MCPServerStatus], nextCursor: String?) {
        self.data = data
        self.nextCursor = nextCursor
    }
}

public struct CommandExecResult: Codable, Sendable {
    public var exitCode: Int
    public var stdout: String
    public var stderr: String

    public init(exitCode: Int, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

public struct WindowsSandboxSetupStartResult: Codable, Sendable {
    public var started: Bool

    public init(started: Bool) {
        self.started = started
    }
}

public struct FeedbackUploadResult: Codable, Sendable {
    public var threadId: String?
    public var conversationId: String?

    public init(threadId: String? = nil, conversationId: String? = nil) {
        self.threadId = threadId
        self.conversationId = conversationId
    }
}

public struct AccountReadResult: Codable, Sendable {
    public var account: Account?
    public var requiresOpenaiAuth: Bool?

    public init(account: Account?, requiresOpenaiAuth: Bool?) {
        self.account = account
        self.requiresOpenaiAuth = requiresOpenaiAuth
    }
}

public struct AccountLoginStartResult: Codable, Sendable {
    public var type: String
    public var loginId: String?
    public var authUrl: String?

    public init(type: String, loginId: String? = nil, authUrl: String? = nil) {
        self.type = type
        self.loginId = loginId
        self.authUrl = authUrl
    }
}

public struct AccountRateLimitsReadResult: Codable, Sendable {
    public var rateLimits: RateLimits?

    public init(rateLimits: RateLimits?) {
        self.rateLimits = rateLimits
    }
}

public struct Thread: Codable, Sendable {
    public var id: String
    public var preview: String?
    public var modelProvider: String?
    public var createdAt: Int?
    public var updatedAt: Int?
    public var status: ThreadStatus?
    public var turns: [Turn]?
    public var name: String?
    public var cwd: String?

    public init(
        id: String,
        preview: String? = nil,
        modelProvider: String? = nil,
        createdAt: Int? = nil,
        updatedAt: Int? = nil,
        status: ThreadStatus? = nil,
        turns: [Turn]? = nil,
        name: String? = nil,
        cwd: String? = nil
    ) {
        self.id = id
        self.preview = preview
        self.modelProvider = modelProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.turns = turns
        self.name = name
        self.cwd = cwd
    }
}

public struct ThreadStatus: Codable, Sendable {
    public var type: String
    public var activeFlags: [String]?

    public init(type: String, activeFlags: [String]? = nil) {
        self.type = type
        self.activeFlags = activeFlags
    }
}

public struct Turn: Codable, Sendable {
    public var id: String
    public var status: String
    public var items: [ThreadItem]
    public var error: TurnError?

    public init(id: String, status: String, items: [ThreadItem], error: TurnError?) {
        self.id = id
        self.status = status
        self.items = items
        self.error = error
    }
}

public struct TurnError: Codable, Sendable {
    public var message: String
    public var codexErrorInfo: JSONValue?
    public var additionalDetails: JSONValue?

    public init(message: String, codexErrorInfo: JSONValue? = nil, additionalDetails: JSONValue? = nil) {
        self.message = message
        self.codexErrorInfo = codexErrorInfo
        self.additionalDetails = additionalDetails
    }
}

public struct ThreadItem: Codable, Sendable {
    public var type: String
    public var id: String?
    public var raw: [String: JSONValue]

    public init(type: String, id: String? = nil, raw: [String: JSONValue] = [:]) {
        self.type = type
        self.id = id
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        var values: [String: JSONValue] = [:]

        for key in container.allKeys {
            values[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
        }

        guard case .string(let typeValue)? = values["type"] else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "ThreadItem missing 'type'.")
            )
        }

        let idValue: String?
        if case .string(let parsedID)? = values["id"] {
            idValue = parsedID
        } else {
            idValue = nil
        }

        self.type = typeValue
        self.id = idValue
        self.raw = values
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        var payload = raw
        payload["type"] = .string(type)

        if let id {
            payload["id"] = .string(id)
        }

        for (key, value) in payload {
            guard let codingKey = AnyCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(value, forKey: codingKey)
        }
    }
}

public struct ThreadStartParams: Codable, Sendable {
    public var model: String?
    public var cwd: String?
    public var approvalPolicy: String?
    public var sandbox: String?
    public var sandboxPolicy: SandboxPolicy?
    public var personality: String?
    public var dynamicTools: [DynamicToolDefinition]?
    public var persistExtendedHistory: Bool?

    public init(
        model: String? = nil,
        cwd: String? = nil,
        approvalPolicy: String? = nil,
        sandbox: String? = nil,
        sandboxPolicy: SandboxPolicy? = nil,
        personality: String? = nil,
        dynamicTools: [DynamicToolDefinition]? = nil,
        persistExtendedHistory: Bool? = nil
    ) {
        self.model = model
        self.cwd = cwd
        self.approvalPolicy = approvalPolicy
        self.sandbox = sandbox
        self.sandboxPolicy = sandboxPolicy
        self.personality = personality
        self.dynamicTools = dynamicTools
        self.persistExtendedHistory = persistExtendedHistory
    }
}

public struct ThreadResumeParams: Codable, Sendable {
    public var threadId: String
    public var model: String?
    public var cwd: String?
    public var approvalPolicy: String?
    public var sandbox: String?
    public var sandboxPolicy: SandboxPolicy?
    public var personality: String?
    public var persistExtendedHistory: Bool?

    public init(
        threadId: String,
        model: String? = nil,
        cwd: String? = nil,
        approvalPolicy: String? = nil,
        sandbox: String? = nil,
        sandboxPolicy: SandboxPolicy? = nil,
        personality: String? = nil,
        persistExtendedHistory: Bool? = nil
    ) {
        self.threadId = threadId
        self.model = model
        self.cwd = cwd
        self.approvalPolicy = approvalPolicy
        self.sandbox = sandbox
        self.sandboxPolicy = sandboxPolicy
        self.personality = personality
        self.persistExtendedHistory = persistExtendedHistory
    }
}

public struct ThreadForkParams: Codable, Sendable {
    public var threadId: String
    public var model: String?
    public var cwd: String?
    public var approvalPolicy: String?
    public var sandbox: String?
    public var sandboxPolicy: SandboxPolicy?
    public var personality: String?
    public var persistExtendedHistory: Bool?

    public init(
        threadId: String,
        model: String? = nil,
        cwd: String? = nil,
        approvalPolicy: String? = nil,
        sandbox: String? = nil,
        sandboxPolicy: SandboxPolicy? = nil,
        personality: String? = nil,
        persistExtendedHistory: Bool? = nil
    ) {
        self.threadId = threadId
        self.model = model
        self.cwd = cwd
        self.approvalPolicy = approvalPolicy
        self.sandbox = sandbox
        self.sandboxPolicy = sandboxPolicy
        self.personality = personality
        self.persistExtendedHistory = persistExtendedHistory
    }
}

public struct ThreadListParams: Codable, Sendable {
    public var cursor: String?
    public var limit: Int?
    public var sortKey: String?
    public var modelProviders: [String]?
    public var sourceKinds: [String]?
    public var archived: Bool?
    public var cwd: String?

    public init(
        cursor: String? = nil,
        limit: Int? = nil,
        sortKey: String? = nil,
        modelProviders: [String]? = nil,
        sourceKinds: [String]? = nil,
        archived: Bool? = nil,
        cwd: String? = nil
    ) {
        self.cursor = cursor
        self.limit = limit
        self.sortKey = sortKey
        self.modelProviders = modelProviders
        self.sourceKinds = sourceKinds
        self.archived = archived
        self.cwd = cwd
    }
}

public struct ThreadReadParams: Codable, Sendable {
    public var threadId: String
    public var includeTurns: Bool?

    public init(threadId: String, includeTurns: Bool? = nil) {
        self.threadId = threadId
        self.includeTurns = includeTurns
    }
}

public struct ThreadIDParams: Codable, Sendable {
    public var threadId: String

    public init(threadId: String) {
        self.threadId = threadId
    }
}

public struct ThreadNameSetParams: Codable, Sendable {
    public var threadId: String
    public var name: String

    public init(threadId: String, name: String) {
        self.threadId = threadId
        self.name = name
    }
}

public struct TurnStartParams: Codable, Sendable {
    public var threadId: String
    public var input: [TurnInputItem]
    public var cwd: String?
    public var approvalPolicy: String?
    public var sandboxPolicy: SandboxPolicy?
    public var model: String?
    public var effort: String?
    public var summary: String?
    public var personality: String?
    public var outputSchema: JSONValue?

    public init(
        threadId: String,
        input: [TurnInputItem],
        cwd: String? = nil,
        approvalPolicy: String? = nil,
        sandboxPolicy: SandboxPolicy? = nil,
        model: String? = nil,
        effort: String? = nil,
        summary: String? = nil,
        personality: String? = nil,
        outputSchema: JSONValue? = nil
    ) {
        self.threadId = threadId
        self.input = input
        self.cwd = cwd
        self.approvalPolicy = approvalPolicy
        self.sandboxPolicy = sandboxPolicy
        self.model = model
        self.effort = effort
        self.summary = summary
        self.personality = personality
        self.outputSchema = outputSchema
    }
}

public struct TurnSteerParams: Codable, Sendable {
    public var threadId: String
    public var input: [TurnInputItem]
    public var expectedTurnId: String

    public init(threadId: String, input: [TurnInputItem], expectedTurnId: String) {
        self.threadId = threadId
        self.input = input
        self.expectedTurnId = expectedTurnId
    }
}

public struct TurnInterruptParams: Codable, Sendable {
    public var threadId: String
    public var turnId: String

    public init(threadId: String, turnId: String) {
        self.threadId = threadId
        self.turnId = turnId
    }
}

public struct ReviewStartParams: Codable, Sendable {
    public var threadId: String
    public var delivery: String?
    public var target: ReviewTarget

    public init(threadId: String, delivery: String? = nil, target: ReviewTarget) {
        self.threadId = threadId
        self.delivery = delivery
        self.target = target
    }
}

public enum ReviewTarget: Codable, Sendable {
    case uncommittedChanges
    case baseBranch(branch: String)
    case commit(sha: String, title: String?)
    case custom(instructions: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case branch
        case sha
        case title
        case instructions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "uncommittedChanges":
            self = .uncommittedChanges
        case "baseBranch":
            self = .baseBranch(branch: try container.decode(String.self, forKey: .branch))
        case "commit":
            self = .commit(
                sha: try container.decode(String.self, forKey: .sha),
                title: try container.decodeIfPresent(String.self, forKey: .title)
            )
        case "custom":
            self = .custom(instructions: try container.decode(String.self, forKey: .instructions))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported review target type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .uncommittedChanges:
            try container.encode("uncommittedChanges", forKey: .type)
        case .baseBranch(let branch):
            try container.encode("baseBranch", forKey: .type)
            try container.encode(branch, forKey: .branch)
        case .commit(let sha, let title):
            try container.encode("commit", forKey: .type)
            try container.encode(sha, forKey: .sha)
            try container.encodeIfPresent(title, forKey: .title)
        case .custom(let instructions):
            try container.encode("custom", forKey: .type)
            try container.encode(instructions, forKey: .instructions)
        }
    }
}

public struct CommandExecParams: Codable, Sendable {
    public var command: [String]
    public var cwd: String?
    public var sandboxPolicy: SandboxPolicy?
    public var timeoutMs: Int?

    public init(command: [String], cwd: String? = nil, sandboxPolicy: SandboxPolicy? = nil, timeoutMs: Int? = nil) {
        self.command = command
        self.cwd = cwd
        self.sandboxPolicy = sandboxPolicy
        self.timeoutMs = timeoutMs
    }
}

public struct ModelListParams: Codable, Sendable {
    public var includeHidden: Bool?

    public init(includeHidden: Bool? = nil) {
        self.includeHidden = includeHidden
    }
}

public struct CursorParams: Codable, Sendable {
    public var cursor: String?
    public var limit: Int?

    public init(cursor: String? = nil, limit: Int? = nil) {
        self.cursor = cursor
        self.limit = limit
    }
}

public struct SkillsListParams: Codable, Sendable {
    public var cwds: [String]?
    public var forceReload: Bool?
    public var perCwdExtraUserRoots: [PerCWDExtraUserRoots]?

    public init(cwds: [String]? = nil, forceReload: Bool? = nil, perCwdExtraUserRoots: [PerCWDExtraUserRoots]? = nil) {
        self.cwds = cwds
        self.forceReload = forceReload
        self.perCwdExtraUserRoots = perCwdExtraUserRoots
    }
}

public struct PerCWDExtraUserRoots: Codable, Sendable {
    public var cwd: String
    public var extraUserRoots: [String]

    public init(cwd: String, extraUserRoots: [String]) {
        self.cwd = cwd
        self.extraUserRoots = extraUserRoots
    }
}

public struct AppListParams: Codable, Sendable {
    public var cursor: String?
    public var limit: Int?
    public var threadId: String?
    public var forceRefetch: Bool?

    public init(cursor: String? = nil, limit: Int? = nil, threadId: String? = nil, forceRefetch: Bool? = nil) {
        self.cursor = cursor
        self.limit = limit
        self.threadId = threadId
        self.forceRefetch = forceRefetch
    }
}

public struct SkillsConfigWriteParams: Codable, Sendable {
    public var path: String
    public var enabled: Bool

    public init(path: String, enabled: Bool) {
        self.path = path
        self.enabled = enabled
    }
}

public struct MCPServerOAuthLoginParams: Codable, Sendable {
    public var name: String

    public init(name: String) {
        self.name = name
    }
}

public struct WindowsSandboxSetupStartParams: Codable, Sendable {
    public var mode: String

    public init(mode: String) {
        self.mode = mode
    }
}

public struct FeedbackUploadParams: Codable, Sendable {
    public var classification: String
    public var reason: String?
    public var logs: String?
    public var conversationId: String?

    public init(classification: String, reason: String? = nil, logs: String? = nil, conversationId: String? = nil) {
        self.classification = classification
        self.reason = reason
        self.logs = logs
        self.conversationId = conversationId
    }
}

public struct ConfigValueWriteParams: Codable, Sendable {
    public var key: String
    public var value: JSONValue

    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

public struct ConfigBatchWriteParams: Codable, Sendable {
    public var edits: [ConfigEdit]

    public init(edits: [ConfigEdit]) {
        self.edits = edits
    }
}

public struct ConfigEdit: Codable, Sendable {
    public var key: String
    public var value: JSONValue

    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

public struct AccountReadParams: Codable, Sendable {
    public var refreshToken: Bool?

    public init(refreshToken: Bool? = nil) {
        self.refreshToken = refreshToken
    }
}

public struct AccountLoginStartParams: Codable, Sendable {
    public var type: String
    public var apiKey: String?

    public init(type: String, apiKey: String? = nil) {
        self.type = type
        self.apiKey = apiKey
    }
}

public struct AccountLoginCancelParams: Codable, Sendable {
    public var loginId: String

    public init(loginId: String) {
        self.loginId = loginId
    }
}

public enum TurnInputItem: Codable, Sendable {
    case text(String)
    case image(url: String)
    case localImage(path: String)
    case skill(name: String, path: String)
    case mention(name: String, path: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case url
        case path
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .text))
        case "image":
            self = .image(url: try container.decode(String.self, forKey: .url))
        case "localImage":
            self = .localImage(path: try container.decode(String.self, forKey: .path))
        case "skill":
            self = .skill(
                name: try container.decode(String.self, forKey: .name),
                path: try container.decode(String.self, forKey: .path)
            )
        case "mention":
            self = .mention(
                name: try container.decode(String.self, forKey: .name),
                path: try container.decode(String.self, forKey: .path)
            )
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported input type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let url):
            try container.encode("image", forKey: .type)
            try container.encode(url, forKey: .url)
        case .localImage(let path):
            try container.encode("localImage", forKey: .type)
            try container.encode(path, forKey: .path)
        case .skill(let name, let path):
            try container.encode("skill", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(path, forKey: .path)
        case .mention(let name, let path):
            try container.encode("mention", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(path, forKey: .path)
        }
    }
}

public enum SandboxPolicy: Codable, Sendable {
    case dangerFullAccess
    case readOnly
    case workspaceWrite(writableRoots: [String]?, networkAccess: Bool?)
    case externalSandbox(networkAccess: String?)
    case custom(type: String, raw: [String: JSONValue])

    private enum CodingKeys: String, CodingKey {
        case type
        case writableRoots
        case networkAccess
    }

    public init(from decoder: Decoder) throws {
        let rawValue = try JSONValue(from: decoder)
        guard case .object(let raw) = rawValue else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "SandboxPolicy must be a JSON object."))
        }

        guard case .string(let type)? = raw["type"] else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "SandboxPolicy missing 'type'."))
        }

        switch type {
        case "dangerFullAccess":
            self = .dangerFullAccess
        case "readOnly":
            self = .readOnly
        case "workspaceWrite":
            let writableRoots: [String]?
            if case .array(let roots)? = raw["writableRoots"] {
                writableRoots = roots.compactMap { $0.stringValue }
            } else {
                writableRoots = nil
            }

            let networkAccess: Bool?
            if case .bool(let value)? = raw["networkAccess"] {
                networkAccess = value
            } else {
                networkAccess = nil
            }

            self = .workspaceWrite(
                writableRoots: writableRoots,
                networkAccess: networkAccess
            )
        case "externalSandbox":
            self = .externalSandbox(networkAccess: raw["networkAccess"]?.stringValue)
        default:
            self = .custom(type: type, raw: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .dangerFullAccess:
            try container.encode("dangerFullAccess", forKey: .type)
        case .readOnly:
            try container.encode("readOnly", forKey: .type)
        case .workspaceWrite(let writableRoots, let networkAccess):
            try container.encode("workspaceWrite", forKey: .type)
            try container.encodeIfPresent(writableRoots, forKey: .writableRoots)
            try container.encodeIfPresent(networkAccess, forKey: .networkAccess)
        case .externalSandbox(let networkAccess):
            try container.encode("externalSandbox", forKey: .type)
            try container.encodeIfPresent(networkAccess, forKey: .networkAccess)
        case .custom(let type, let raw):
            var dynamicContainer = encoder.container(keyedBy: AnyCodingKey.self)
            try dynamicContainer.encode(JSONValue.string(type), forKey: AnyCodingKey("type"))
            for (key, value) in raw where key != "type" {
                try dynamicContainer.encode(value, forKey: AnyCodingKey(key))
            }
        }
    }
}

public struct DynamicToolDefinition: Codable, Sendable {
    public var name: String
    public var description: String
    public var inputSchema: JSONValue

    public init(name: String, description: String, inputSchema: JSONValue) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public struct ModelInfo: Codable, Sendable {
    public var id: String
    public var provider: String?
    public var hidden: Bool?
    public var effortOptions: [String]?
    public var upgrade: String?

    public init(id: String, provider: String? = nil, hidden: Bool? = nil, effortOptions: [String]? = nil, upgrade: String? = nil) {
        self.id = id
        self.provider = provider
        self.hidden = hidden
        self.effortOptions = effortOptions
        self.upgrade = upgrade
    }
}

public struct ExperimentalFeature: Codable, Sendable {
    public var id: String
    public var stage: String?
    public var enabled: Bool?
    public var defaultEnabled: Bool?
    public var displayName: String?
    public var description: String?
    public var announcement: String?

    public init(id: String, stage: String? = nil, enabled: Bool? = nil, defaultEnabled: Bool? = nil, displayName: String? = nil, description: String? = nil, announcement: String? = nil) {
        self.id = id
        self.stage = stage
        self.enabled = enabled
        self.defaultEnabled = defaultEnabled
        self.displayName = displayName
        self.description = description
        self.announcement = announcement
    }
}

public struct CollaborationMode: Codable, Sendable {
    public var id: String
    public var title: String?
    public var description: String?

    public init(id: String, title: String? = nil, description: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
    }
}

public struct SkillsByCWD: Codable, Sendable {
    public var cwd: String
    public var skills: [SkillInfo]
    public var errors: [String]?

    public init(cwd: String, skills: [SkillInfo], errors: [String]? = nil) {
        self.cwd = cwd
        self.skills = skills
        self.errors = errors
    }
}

public struct SkillInfo: Codable, Sendable {
    public var name: String
    public var description: String?
    public var enabled: Bool?
    public var interface: SkillInterface?

    public init(name: String, description: String? = nil, enabled: Bool? = nil, interface: SkillInterface? = nil) {
        self.name = name
        self.description = description
        self.enabled = enabled
        self.interface = interface
    }
}

public struct SkillInterface: Codable, Sendable {
    public var displayName: String?
    public var shortDescription: String?
    public var iconSmall: String?
    public var iconLarge: String?
    public var brandColor: String?
    public var defaultPrompt: String?

    public init(
        displayName: String? = nil,
        shortDescription: String? = nil,
        iconSmall: String? = nil,
        iconLarge: String? = nil,
        brandColor: String? = nil,
        defaultPrompt: String? = nil
    ) {
        self.displayName = displayName
        self.shortDescription = shortDescription
        self.iconSmall = iconSmall
        self.iconLarge = iconLarge
        self.brandColor = brandColor
        self.defaultPrompt = defaultPrompt
    }
}

public struct AppInfo: Codable, Sendable {
    public var id: String
    public var name: String
    public var description: String?
    public var logoUrl: String?
    public var logoUrlDark: String?
    public var distributionChannel: String?
    public var branding: JSONValue?
    public var appMetadata: JSONValue?
    public var labels: JSONValue?
    public var installUrl: String?
    public var isAccessible: Bool?
    public var isEnabled: Bool?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        logoUrl: String? = nil,
        logoUrlDark: String? = nil,
        distributionChannel: String? = nil,
        branding: JSONValue? = nil,
        appMetadata: JSONValue? = nil,
        labels: JSONValue? = nil,
        installUrl: String? = nil,
        isAccessible: Bool? = nil,
        isEnabled: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.logoUrl = logoUrl
        self.logoUrlDark = logoUrlDark
        self.distributionChannel = distributionChannel
        self.branding = branding
        self.appMetadata = appMetadata
        self.labels = labels
        self.installUrl = installUrl
        self.isAccessible = isAccessible
        self.isEnabled = isEnabled
    }
}

public struct MCPServerStatus: Codable, Sendable {
    public var name: String
    public var authStatus: String?
    public var tools: [JSONValue]?
    public var resources: [JSONValue]?
    public var resourceTemplates: [JSONValue]?

    public init(name: String, authStatus: String? = nil, tools: [JSONValue]? = nil, resources: [JSONValue]? = nil, resourceTemplates: [JSONValue]? = nil) {
        self.name = name
        self.authStatus = authStatus
        self.tools = tools
        self.resources = resources
        self.resourceTemplates = resourceTemplates
    }
}

public enum Account: Codable, Sendable {
    case apiKey
    case chatgpt(email: String?, planType: String?)
    case custom(type: String, raw: [String: JSONValue])

    private enum CodingKeys: String, CodingKey {
        case type
        case email
        case planType
    }

    public init(from decoder: Decoder) throws {
        let rawValue = try JSONValue(from: decoder)
        guard case .object(let raw) = rawValue else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Account must be a JSON object."))
        }

        guard case .string(let type)? = raw["type"] else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Account missing 'type'."))
        }

        switch type {
        case "apiKey":
            self = .apiKey
        case "chatgpt":
            self = .chatgpt(
                email: raw["email"]?.stringValue,
                planType: raw["planType"]?.stringValue
            )
        default:
            self = .custom(type: type, raw: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .apiKey:
            try container.encode("apiKey", forKey: .type)
        case .chatgpt(let email, let planType):
            try container.encode("chatgpt", forKey: .type)
            try container.encodeIfPresent(email, forKey: .email)
            try container.encodeIfPresent(planType, forKey: .planType)
        case .custom(let type, let raw):
            var dynamicContainer = encoder.container(keyedBy: AnyCodingKey.self)
            try dynamicContainer.encode(JSONValue.string(type), forKey: AnyCodingKey("type"))
            for (key, value) in raw where key != "type" {
                try dynamicContainer.encode(value, forKey: AnyCodingKey(key))
            }
        }
    }
}

public struct RateLimits: Codable, Sendable {
    public var primary: RateLimitWindow?
    public var secondary: RateLimitWindow?

    public init(primary: RateLimitWindow? = nil, secondary: RateLimitWindow? = nil) {
        self.primary = primary
        self.secondary = secondary
    }
}

public struct RateLimitWindow: Codable, Sendable {
    public var usedPercent: Double?
    public var windowDurationMins: Int?
    public var resetsAt: Int?

    public init(usedPercent: Double? = nil, windowDurationMins: Int? = nil, resetsAt: Int? = nil) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }
}

public struct ApprovalRequestBase: Codable, Sendable {
    public var itemId: String
    public var threadId: String
    public var turnId: String
    public var reason: String?

    public init(itemId: String, threadId: String, turnId: String, reason: String? = nil) {
        self.itemId = itemId
        self.threadId = threadId
        self.turnId = turnId
        self.reason = reason
    }
}

public struct CommandExecutionApprovalRequest: Codable, Sendable {
    public var itemId: String
    public var threadId: String
    public var turnId: String
    public var approvalId: String?
    public var reason: String?
    public var command: [String]?
    public var cwd: String?
    public var commandActions: [JSONValue]?

    public init(
        itemId: String,
        threadId: String,
        turnId: String,
        approvalId: String? = nil,
        reason: String? = nil,
        command: [String]? = nil,
        cwd: String? = nil,
        commandActions: [JSONValue]? = nil
    ) {
        self.itemId = itemId
        self.threadId = threadId
        self.turnId = turnId
        self.approvalId = approvalId
        self.reason = reason
        self.command = command
        self.cwd = cwd
        self.commandActions = commandActions
    }
}

public struct FileChangeApprovalRequest: Codable, Sendable {
    public var itemId: String
    public var threadId: String
    public var turnId: String
    public var reason: String?

    public init(itemId: String, threadId: String, turnId: String, reason: String? = nil) {
        self.itemId = itemId
        self.threadId = threadId
        self.turnId = turnId
        self.reason = reason
    }
}

public struct DynamicToolCallRequest: Codable, Sendable {
    public var threadId: String
    public var turnId: String
    public var callId: String
    public var tool: String
    public var arguments: JSONValue

    public init(threadId: String, turnId: String, callId: String, tool: String, arguments: JSONValue) {
        self.threadId = threadId
        self.turnId = turnId
        self.callId = callId
        self.tool = tool
        self.arguments = arguments
    }
}

public struct ApprovalDecisionResponse: Codable, Sendable {
    public var decision: String
    public var acceptSettings: CommandApprovalAcceptSettings?

    public init(decision: String, acceptSettings: CommandApprovalAcceptSettings? = nil) {
        self.decision = decision
        self.acceptSettings = acceptSettings
    }

    public static func accept(forSession: Bool? = nil) -> ApprovalDecisionResponse {
        let settings = forSession.map { CommandApprovalAcceptSettings(forSession: $0) }
        return ApprovalDecisionResponse(decision: "accept", acceptSettings: settings)
    }

    public static func decline() -> ApprovalDecisionResponse {
        ApprovalDecisionResponse(decision: "decline")
    }
}

public struct CommandApprovalAcceptSettings: Codable, Sendable {
    public var forSession: Bool

    public init(forSession: Bool) {
        self.forSession = forSession
    }
}

public struct DynamicToolCallResponse: Codable, Sendable {
    public var contentItems: [DynamicToolContentItem]
    public var success: Bool

    public init(contentItems: [DynamicToolContentItem], success: Bool) {
        self.contentItems = contentItems
        self.success = success
    }
}

public enum DynamicToolContentItem: Codable, Sendable {
    case inputText(String)
    case inputImage(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "inputText":
            self = .inputText(try container.decode(String.self, forKey: .text))
        case "inputImage":
            self = .inputImage(try container.decode(String.self, forKey: .imageUrl))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported dynamic tool content item type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .inputText(let value):
            try container.encode("inputText", forKey: .type)
            try container.encode(value, forKey: .text)
        case .inputImage(let value):
            try container.encode("inputImage", forKey: .type)
            try container.encode(value, forKey: .imageUrl)
        }
    }
}

public struct ToolRequestUserInputQuestion: Codable, Sendable {
    public var header: String
    public var id: String
    public var question: String
    public var options: [ToolRequestUserInputOption]

    public init(header: String, id: String, question: String, options: [ToolRequestUserInputOption]) {
        self.header = header
        self.id = id
        self.question = question
        self.options = options
    }
}

public struct ToolRequestUserInputOption: Codable, Sendable {
    public var label: String
    public var description: String

    public init(label: String, description: String) {
        self.label = label
        self.description = description
    }
}

public struct ToolRequestUserInputParams: Codable, Sendable {
    public var questions: [ToolRequestUserInputQuestion]

    public init(questions: [ToolRequestUserInputQuestion]) {
        self.questions = questions
    }
}

public struct AnyCodingKey: CodingKey, Hashable, Sendable {
    public let stringValue: String
    public let intValue: Int?

    public init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
