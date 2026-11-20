import Foundation

public struct RateLimitFailure: Sendable, Equatable, Hashable {
    public let retryAfterSeconds: Int
    public let isSignInDelayed: Bool

    public init(
        retryAfterSeconds: Int,
        isSignInDelayed: Bool,
    ) {
        self.retryAfterSeconds = retryAfterSeconds
        self.isSignInDelayed = isSignInDelayed
    }
}
