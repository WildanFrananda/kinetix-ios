import Foundation
import KinetixDomain

nonisolated public enum TwoFactorSettingsState: Sendable, Equatable {
    case idle
    case submitting
    case setupReady(TwoFactorSetup)
    case enabled
    case disabled
    case alreadyEnabled
    case notEnabled
    case invalidCode
    case rateLimited(secondsRemaining: Int, isSignInDelayed: Bool)
    case failed(Failure)
}
