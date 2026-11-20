import Foundation

public struct UserIdentity: Sendable, Equatable, Hashable, Codable {
    public let accountId: AccountId
    public let principalId: PrincipalId
    public let email: String
    public let role: UserRole

    public init(
        accountId: AccountId,
        principalId: PrincipalId,
        email: String,
        role: UserRole,
    ) {
        self.accountId = accountId
        self.principalId = principalId
        self.email = email
        self.role = role
    }
}
