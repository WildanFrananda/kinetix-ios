import Foundation
import KinetixDomain

public struct LoginResponseDTO: Decodable, Sendable, Equatable {
    public let accessToken: String?
    public let refreshToken: String?
    public let expiresIn: Int?
    public let tokenType: String?
    public let user: AuthUserDTO?
    public let mfaRequired: Bool?
    public let challengeToken: String?
    public let passkeys: Bool?
    public let mfaEnrolmentRequired: Bool?
    public let enrolmentToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresIn
        case tokenType
        case user
        case mfaRequired
        case challengeToken
        case passkeys
        case mfaEnrolmentRequired
        case enrolmentToken
    }

    public func toDomain(issuedAt: Date) -> Result<SignInOutcome, Failure> {
        if mfaEnrolmentRequired == true {
            return .failure(.unsupportedAccountRole)
        }

        if mfaRequired == true {
            guard let challengeToken, let expiresIn, expiresIn > 0 else {
                return .failure(.unreadableResponse)
            }

            let challenge = TwoFactorChallenge(
                challengeToken: challengeToken,
                expiresAt: issuedAt.addingTimeInterval(TimeInterval(expiresIn)),
                hasPasskeys: passkeys ?? false,
            )
            return .success(.twoFactorRequired(challenge))
        }

        guard
            let accessToken,
            let refreshToken,
            let expiresIn,
            expiresIn > 0,
            let userDTO = user,
            let domainUser = userDTO.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        let session = AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: issuedAt.addingTimeInterval(TimeInterval(expiresIn)),
            user: domainUser,
        )
        return .success(.signedIn(session))
    }
}
