import Foundation

public struct TwoFactorEnableRequestDTO: Encodable, Sendable, Equatable {
    public let code: String
    public let password: String

    public init(
        code: String,
        password: String,
    ) {
        self.code = code
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case code
        case password
    }
}
