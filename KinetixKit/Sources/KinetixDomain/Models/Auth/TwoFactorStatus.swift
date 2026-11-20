import Foundation

public struct TwoFactorStatus: Sendable, Equatable {
    public let enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}
