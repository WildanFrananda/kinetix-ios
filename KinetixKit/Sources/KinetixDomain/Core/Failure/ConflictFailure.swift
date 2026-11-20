import Foundation

public struct ConflictFailure: Sendable, Equatable, Hashable {
    public let code: String?

    public init(code: String? = nil) {
        self.code = code
    }
}
