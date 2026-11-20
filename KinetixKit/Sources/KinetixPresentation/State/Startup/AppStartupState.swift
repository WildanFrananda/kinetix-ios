import Foundation
import KinetixDomain

nonisolated public enum AppStartupState: Sendable, Equatable {
    case validating
    case invalidConfiguration([AppConfigIssue])
    case configured(AppConfig)
}
