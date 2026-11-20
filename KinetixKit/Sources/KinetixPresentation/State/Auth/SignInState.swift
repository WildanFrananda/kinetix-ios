import Foundation
import KinetixDomain

nonisolated public enum SignInState: Sendable, Equatable {
    case idle
    case submitting
    case rateLimited(secondsRemaining: Int, isSignInDelayed: Bool)
    case failed(Failure)
    case signedIn(AuthSession)
    case twoFactorRequired(TwoFactorChallenge)
}
