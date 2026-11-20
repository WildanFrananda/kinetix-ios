import Foundation
import KinetixData
import KinetixDomain
import Testing

struct KeychainSessionVaultTests {
    @Test
    func storesUpdatesAndClearsSessionInIsolatedKeychainService() throws {
        let serviceName = "com.kinetix.shop.tests.\(UUID().uuidString)"
        let vault = KeychainSessionVault(service: serviceName, account: "test-session")
        defer { _ = vault.clear() }

        #expect(vault.read() == .signedOut)

        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let first = AuthSession(
            accessToken: "access-1",
            refreshToken: "refresh-1",
            expiresAt: Date(timeIntervalSince1970: 1_760_000_900),
            user: UserIdentity(
                accountId: accountId,
                principalId: principalId,
                email: "buyer@example.test",
                role: .customer,
            ),
        )

        if case .failure(let failure) = vault.write(first) {
            Issue.record("Expected first Keychain write to succeed, got \(failure)")
        }

        #expect(vault.read() == .signedIn(first))

        let rotated = AuthSession(
            accessToken: "access-2",
            refreshToken: "refresh-2",
            expiresAt: Date(timeIntervalSince1970: 1_760_001_800),
            user: first.user,
        )
        if case .failure(let failure) = vault.write(rotated) {
            Issue.record("Expected Keychain update to succeed, got \(failure)")
        }

        #expect(vault.read() == .signedIn(rotated))

        if case .failure(let failure) = vault.clear() {
            Issue.record("Expected Keychain clear to succeed, got \(failure)")
        }

        #expect(vault.read() == .signedOut)
    }
}
