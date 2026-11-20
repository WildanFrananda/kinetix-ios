import Foundation

public struct UnprocessableFailure: Sendable, Equatable, Hashable {
    public let code: String?
    public let messages: [String]

    public init(
        code: String? = nil,
        messages: [String] = [],
    ) {
        self.code = code
        self.messages = messages
    }
}
