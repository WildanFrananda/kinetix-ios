import Foundation
import KinetixDomain

public struct TwoFactorStatusResponseDTO: Decodable, Sendable, Equatable {
    public let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case enabled
    }

    public func toDomain() -> TwoFactorStatus {
        return TwoFactorStatus(enabled: enabled)
    }
}
