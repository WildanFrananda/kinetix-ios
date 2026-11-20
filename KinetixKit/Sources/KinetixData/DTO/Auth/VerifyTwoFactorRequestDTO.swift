import Foundation

public struct VerifyTwoFactorRequestDTO: Encodable, Sendable, Equatable {
    public let challengeToken: String
    public let code: String

    public init(
        challengeToken: String,
        code: String,
    ) {
        self.challengeToken = challengeToken
        self.code = code
    }

    enum CodingKeys: String, CodingKey {
        case challengeToken
        case code
    }
}
