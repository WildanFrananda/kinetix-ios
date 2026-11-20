import Foundation

public struct ApiErrorEnvelope: Sendable, Equatable {
    public let error: String?
    public let code: String?
    public let messages: [String]
    public let retryAfterSeconds: Int?
    public let field: String?
    public let traceId: String?
    public let isServiceJSON: Bool

    public init(
        error: String? = nil,
        code: String? = nil,
        messages: [String] = [],
        retryAfterSeconds: Int? = nil,
        field: String? = nil,
        traceId: String? = nil,
        isServiceJSON: Bool = false,
    ) {
        self.error = error
        self.code = code
        self.messages = messages
        self.retryAfterSeconds = retryAfterSeconds
        self.field = field
        self.traceId = traceId
        self.isServiceJSON = isServiceJSON
    }

    public var machineCode: String? {
        if let code, Self.looksLikeMachineCode(code) {
            return code
        }

        if let error, Self.looksLikeMachineCode(error) {
            return error
        }

        return nil
    }

    private static func looksLikeMachineCode(_ value: String) -> Bool {
        guard !value.isEmpty && !value.contains(" ") else {
            return false
        }

        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
        )
        return value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
