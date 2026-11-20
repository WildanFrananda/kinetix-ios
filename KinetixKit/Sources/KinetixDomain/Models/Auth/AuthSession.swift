import Foundation

public struct AuthSession: Sendable, Equatable, Hashable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let user: UserIdentity

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        user: UserIdentity,
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
}
