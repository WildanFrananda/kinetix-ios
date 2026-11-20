import Foundation
import KinetixDomain

nonisolated public enum AppStartupState: Sendable, Equatable {
    case validating
    case invalidConfiguration([AppConfigIssue])
    case configured(AppConfig)
    case checkingSession(AppConfig)
    case signedOut(AppConfig)
    case signedIn(AppConfig, AuthSession)
    case sessionCheckFailed(AppConfig, Failure)
}
