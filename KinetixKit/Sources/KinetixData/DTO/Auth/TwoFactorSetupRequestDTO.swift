import Foundation

public struct TwoFactorSetupRequestDTO: Encodable, Sendable, Equatable {
    public let password: String

    public init(password: String) {
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case password
    }
}
