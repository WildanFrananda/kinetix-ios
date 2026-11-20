import Foundation
import KinetixDomain
import Synchronization

public final class FakeLanguagePreferenceStore: LanguagePreferenceStore {
    private let current = Mutex<AppLanguage>(.system)

    public init(initial: AppLanguage = .system) {
        current.withLock { $0 = initial }
    }

    public func loadLanguage() -> AppLanguage {
        return current.withLock { $0 }
    }

    public func saveLanguage(_ language: AppLanguage) {
        current.withLock { $0 = language }
    }
}
