import Foundation
import KinetixDomain

public struct AuthUserDTO: Decodable, Sendable, Equatable {
    public let id: Int
    public let email: String
    public let role: String
    public let principalId: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case principalId
    }

    public func toDomain() -> UserIdentity? {
        guard
            let accountId = AccountId(id),
            let principal = PrincipalId(principalId)
        else {
            return nil
        }

        return UserIdentity(
            accountId: accountId,
            principalId: principal,
            email: email,
            role: UserRole(rawWireValue: role),
        )
    }
}
