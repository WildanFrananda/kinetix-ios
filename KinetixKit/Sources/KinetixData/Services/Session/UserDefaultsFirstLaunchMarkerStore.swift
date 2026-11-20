import Foundation

public struct UserDefaultsFirstLaunchMarkerStore: FirstLaunchMarkerStore {
    private let key: String
    private let suiteName: String?

    public init(
        suiteName: String? = nil,
        key: String = "com.kinetix.shop.has-completed-first-launch",
    ) {
        self.suiteName = suiteName
        self.key = key
    }

    public func hasCompletedFirstLaunch() -> Bool {
        let defaults = resolveDefaults()
        return defaults.bool(forKey: key)
    }

    public func markFirstLaunchCompleted() {
        let defaults = resolveDefaults()
        defaults.set(true, forKey: key)
    }

    private func resolveDefaults() -> UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }

        return .standard
    }
}
