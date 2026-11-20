import Foundation
import KinetixDomain

public struct AuthSessionResponseDTO: Decodable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let user: AuthUserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresIn
        case tokenType
        case user
    }

    public func toDomain(issuedAt: Date) -> AuthSession? {
        guard expiresIn > 0, let domainUser = user.toDomain() else {
            return nil
        }

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: issuedAt.addingTimeInterval(TimeInterval(expiresIn)),
            user: domainUser,
        )
    }
}
