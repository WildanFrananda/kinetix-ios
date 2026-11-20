import Foundation
import KinetixDomain
import Observation

@Observable
public final class LanguageSettingsViewModel {
    public private(set) var selectedLanguage: AppLanguage

    private let store: any LanguagePreferenceStore

    public init(store: any LanguagePreferenceStore) {
        self.store = store
        self.selectedLanguage = store.loadLanguage()
    }

    public var activeLocaleOverride: Locale? {
        return selectedLanguage.localeOverride
    }

    public func selectLanguage(_ language: AppLanguage) {
        guard selectedLanguage != language else {
            return
        }

        selectedLanguage = language
        store.saveLanguage(language)
    }
}
