import Foundation

public struct UnauthorizedFailure: Sendable, Equatable, Hashable {
    public let code: String?

    public init(code: String? = nil) {
        self.code = code
    }
}
