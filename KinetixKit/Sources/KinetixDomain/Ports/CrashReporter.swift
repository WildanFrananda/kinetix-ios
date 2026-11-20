import Foundation

public protocol CrashReporter: Sendable {
    func setUserPrincipal(_ principalId: PrincipalId?)
    func recordNonFatal(
        code: String,
        context: [String: String],
    )
}
