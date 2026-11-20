import Foundation

public struct LoginRequestDTO: Encodable, Sendable, Equatable {
    public let email: String
    public let password: String

    public init(
        email: String,
        password: String,
    ) {
        self.email = email
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}
