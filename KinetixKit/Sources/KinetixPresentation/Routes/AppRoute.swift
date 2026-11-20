import Foundation
import KinetixDomain

nonisolated public enum AppRoute: Hashable, Codable, Sendable {
    case signIn
    case register
    case twoFactorChallenge
    case search
    case productDetail(ProductSku)
    case languageSettings
    case account
    case profile
    case twoFactorSettings

    public var requiresSession: Bool {
        switch self {
        case .signIn, .register, .twoFactorChallenge, .search, .productDetail, .languageSettings:
            return false
        case .account, .profile, .twoFactorSettings:
            return true
        }
    }

    public var isAuthEntryRoute: Bool {
        switch self {
        case .signIn, .register, .twoFactorChallenge:
            return true
        case .search, .productDetail, .languageSettings, .account, .profile, .twoFactorSettings:
            return false
        }
    }
}
