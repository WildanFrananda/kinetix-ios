import Foundation

public struct RefreshRequestDTO: Encodable, Sendable, Equatable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    enum CodingKeys: String, CodingKey {
        case refreshToken
    }
}
