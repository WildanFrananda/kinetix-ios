import Foundation

public enum SignInOutcome: Sendable, Equatable {
    case signedIn(AuthSession)
    case twoFactorRequired(TwoFactorChallenge)
}
