import Foundation

public struct TwoFactorSetup: Sendable, Equatable {
    public let secret: String
    public let qrCodeURL: String
    public let enabled: Bool

    public init(
        secret: String,
        qrCodeURL: String,
        enabled: Bool,
    ) {
        self.secret = secret
        self.qrCodeURL = qrCodeURL
        self.enabled = enabled
    }
}
