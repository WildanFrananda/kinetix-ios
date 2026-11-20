import Foundation
import KinetixDomain

public struct TwoFactorSetupResponseDTO: Decodable, Sendable, Equatable {
    public let twoFactorSecret: String
    public let qrCodeUrl: String
    public let enabled: Bool

    enum CodingKeys: String, CodingKey {
        case twoFactorSecret
        case qrCodeUrl
        case enabled
    }

    public func toDomain() -> TwoFactorSetup {
        return TwoFactorSetup(
            secret: twoFactorSecret,
            qrCodeURL: qrCodeUrl,
            enabled: enabled,
        )
    }
}
