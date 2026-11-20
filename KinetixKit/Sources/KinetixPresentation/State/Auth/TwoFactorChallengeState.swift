import Foundation
import KinetixDomain

nonisolated public enum TwoFactorChallengeState: Sendable, Equatable {
    case idle
    case submitting
    case wrongCode
    case challengeClosed
    case rateLimited(secondsRemaining: Int, isSignInDelayed: Bool)
    case failed(Failure)
    case verified(AuthSession)
}
