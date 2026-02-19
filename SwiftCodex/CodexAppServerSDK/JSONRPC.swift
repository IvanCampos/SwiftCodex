import Foundation

public enum JSONRPCID: Hashable, Codable, Sendable {
    case int(Int64)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int64.self) {
            self = .int(intValue)
            return
        }

        let stringValue = try container.decode(String.self)
        self = .string(stringValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

public struct JSONRPCErrorObject: Error, Codable, Sendable {
    public let code: Int
    public let message: String
    public let data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public enum CodexAppServerError: Error, Sendable {
    case notConnected
    case processAlreadyRunning
    case unsupportedPlatform(String)
    case invalidWebSocketURL(String)
    case websocketHandshakeFailed(String)
    case websocketProtocolViolation(String)
    case failedToEncodeOutboundMessage
    case malformedInboundMessage
    case rpc(JSONRPCErrorObject)
    case missingResult(JSONRPCID)
    case terminated(Int32)
}

public struct AnyEncodable: Encodable {
    private let encodeImpl: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        self.encodeImpl = value.encode
    }

    public func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}

public struct JSONRPCIncomingEnvelope: Decodable, Sendable {
    public let id: JSONRPCID?
    public let method: String?
    public let params: JSONValue?
    public let result: JSONValue?
    public let error: JSONRPCErrorObject?
}

public struct JSONRPCOutgoingEnvelope: Encodable, Sendable {
    public let id: JSONRPCID?
    public let method: String?
    public let params: AnyEncodable?
    public let result: AnyEncodable?
    public let error: JSONRPCErrorObject?

    public init(
        id: JSONRPCID? = nil,
        method: String? = nil,
        params: AnyEncodable? = nil,
        result: AnyEncodable? = nil,
        error: JSONRPCErrorObject? = nil
    ) {
        self.id = id
        self.method = method
        self.params = params
        self.result = result
        self.error = error
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case method
        case params
        case result
        case error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let id {
            try container.encode(id, forKey: .id)
        }

        if let method {
            try container.encode(method, forKey: .method)
        }

        if let params {
            try container.encode(params, forKey: .params)
        }

        if let result {
            try container.encode(result, forKey: .result)
        }

        if let error {
            try container.encode(error, forKey: .error)
        }
    }
}

public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelayNanoseconds: UInt64
    public let maxDelayNanoseconds: UInt64

    public init(maxAttempts: Int = 5, baseDelayNanoseconds: UInt64 = 200_000_000, maxDelayNanoseconds: UInt64 = 5_000_000_000) {
        self.maxAttempts = maxAttempts
        self.baseDelayNanoseconds = baseDelayNanoseconds
        self.maxDelayNanoseconds = maxDelayNanoseconds
    }

    public static let appServerDefault = RetryPolicy()

    public func delayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        let multiplier = UInt64(1 << min(max(attempt - 1, 0), 30))
        let exponential = min(baseDelayNanoseconds.saturatingMultiply(by: multiplier), maxDelayNanoseconds)

        let jitterCap = max(exponential / 4, 1)
        let jitter = UInt64.random(in: 0..<jitterCap)

        return min(exponential + jitter, maxDelayNanoseconds)
    }
}

private extension UInt64 {
    func saturatingMultiply(by multiplier: UInt64) -> UInt64 {
        let (result, overflow) = multipliedReportingOverflow(by: multiplier)
        return overflow ? UInt64.max : result
    }
}
