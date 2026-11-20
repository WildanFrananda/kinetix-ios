import Foundation
import KinetixDomain

struct UserDefaultsRoutePersistenceStore: RoutePersistenceStore {
    private let keyPrefix = "com.kinetix.shop.route-path."

    func loadEncodedPath(for principalId: PrincipalId) -> Data? {
        return UserDefaults.standard.data(forKey: keyPrefix + principalId.value)
    }

    func saveEncodedPath(
        _ data: Data,
        for principalId: PrincipalId,
    ) {
        UserDefaults.standard.set(data, forKey: keyPrefix + principalId.value)
    }

    func clearPath(for principalId: PrincipalId) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + principalId.value)
    }
}
