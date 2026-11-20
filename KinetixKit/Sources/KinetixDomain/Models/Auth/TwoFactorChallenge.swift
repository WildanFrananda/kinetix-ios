import Foundation

public struct TwoFactorChallenge: Sendable, Equatable, Hashable {
    public let challengeToken: String
    public let expiresAt: Date
    public let hasPasskeys: Bool

    public init(
        challengeToken: String,
        expiresAt: Date,
        hasPasskeys: Bool,
    ) {
        self.challengeToken = challengeToken
        self.expiresAt = expiresAt
        self.hasPasskeys = hasPasskeys
    }
}
