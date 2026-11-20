import Foundation

nonisolated public enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case english = "en"
    case indonesian = "id"

    public var localeOverride: Locale? {
        switch self {
        case .system:
            return nil
        case .english:
            return Locale(identifier: "en")
        case .indonesian:
            return Locale(identifier: "id")
        }
    }
}
