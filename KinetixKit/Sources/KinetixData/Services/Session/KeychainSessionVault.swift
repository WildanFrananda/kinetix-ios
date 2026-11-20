import Foundation
import KinetixDomain
import Security

public struct KeychainSessionVault: SessionVault {
    private let service: String
    private let account: String

    public init(
        service: String = "com.kinetix.shop.session",
        account: String = "primary-session",
    ) {
        self.service = service
        self.account = account
    }

    public func read() -> StoredSessionState {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return .signedOut
        }

        guard status == errSecSuccess, let data = item as? Data else {
            return .unreadable
        }

        guard let session = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            return .unreadable
        }

        return .signedIn(session)
    }

    public func write(_ session: AuthSession) -> Result<Void, Failure> {
        guard let encoded = try? JSONEncoder().encode(session) else {
            return .failure(.sessionUnavailable)
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: encoded,
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return .success(())
        }

        if addStatus == errSecDuplicateItem {
            let matchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            let updateAttributes: [String: Any] = [
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecValueData as String: encoded,
            ]
            let updateStatus = SecItemUpdate(
                matchQuery as CFDictionary,
                updateAttributes as CFDictionary,
            )
            if updateStatus == errSecSuccess {
                return .success(())
            }
        }

        return .failure(.sessionUnavailable)
    }

    public func clear() -> Result<Void, Failure> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return .success(())
        }

        return .failure(.sessionUnavailable)
    }
}
