import Foundation

public protocol LanguagePreferenceStore: Sendable {
    func loadLanguage() -> AppLanguage
    func saveLanguage(_ language: AppLanguage)
}
