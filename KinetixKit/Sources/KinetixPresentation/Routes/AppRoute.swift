import Foundation

nonisolated public enum AppRoute: Hashable, Codable, Sendable {
    case register
    case twoFactorChallenge
    case profile
    case twoFactorSettings

    public var requiresSession: Bool {
        switch self {
        case .register, .twoFactorChallenge:
            return false
        case .profile, .twoFactorSettings:
            return true
        }
    }
}
