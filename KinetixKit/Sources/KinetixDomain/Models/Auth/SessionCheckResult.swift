import Foundation

public struct SessionCheckResult: Sendable, Equatable {
    public let principalId: PrincipalId
    public let accountId: AccountId
    public let email: String
    public let role: UserRole
    public let expiresAt: Date

    public init(
        principalId: PrincipalId,
        accountId: AccountId,
        email: String,
        role: UserRole,
        expiresAt: Date,
    ) {
        self.principalId = principalId
        self.accountId = accountId
        self.email = email
        self.role = role
        self.expiresAt = expiresAt
    }
}
