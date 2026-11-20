import Foundation
import KinetixDomain

public struct AuthMeResponseDTO: Decodable, Sendable, Equatable {
    public let principalId: String
    public let userId: Int
    public let email: String
    public let role: String
    public let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case principalId
        case userId
        case email
        case role
        case expiresAt
    }

    public func toDomain() -> SessionCheckResult? {
        guard
            let principal = PrincipalId(principalId),
            let accountId = AccountId(userId),
            let parsedExpiresAt = WireTimestamp.parseRFC3339(expiresAt)
        else {
            return nil
        }

        return SessionCheckResult(
            principalId: principal,
            accountId: accountId,
            email: email,
            role: UserRole(rawWireValue: role),
            expiresAt: parsedExpiresAt,
        )
    }
}
