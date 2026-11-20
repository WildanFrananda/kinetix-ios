import Foundation
import KinetixDomain

struct UserDefaultsLanguagePreferenceStore: LanguagePreferenceStore {
    private let key = "com.kinetix.shop.language-preference"

    func loadLanguage() -> AppLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: key),
            let parsed = AppLanguage(rawValue: rawValue)
        else {
            return .system
        }

        return parsed
    }

    func saveLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: key)
    }
}
