import Foundation

public struct ValidationFailure: Sendable, Equatable, Hashable {
    public let code: String?
    public let field: String?
    public let messages: [String]

    public init(
        code: String? = nil,
        field: String? = nil,
        messages: [String] = [],
    ) {
        self.code = code
        self.field = field
        self.messages = messages
    }
}
