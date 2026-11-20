import Foundation
import KinetixData
import KinetixDomain
import KinetixFakes
import Testing

struct SessionRenewerTests {
    @Test
    func coalescesConcurrentRefreshCallersIntoOneNetworkRequest() async throws {
        let clock = FakeAppClock()
        let initial = try makeSession(
            access: "old-access",
            refresh: "old-refresh",
            expiresAt: clock.now().addingTimeInterval(30),
        )
        let vault = FakeSessionVault(initial: .signedIn(initial))

        let refreshedJSON = Data(
            """
            {
              "accessToken": "new-access",
              "refreshToken": "new-refresh",
              "expiresIn": 900,
              "tokenType": "Bearer",
              "user": {
                "id": 42,
                "email": "buyer@example.test",
                "role": "customer",
                "principalId": "0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"
              }
            }
            """.utf8
        )
        let transport = FakeHTTPTransport(
            responses: [
                .success(
                    HTTPResponse(
                        statusCode: 200,
                        headers: [:],
                        body: refreshedJSON,
                        requestId: "req-refresh",
                    )
                )
            ],
            delayNanoseconds: 30_000_000,
        )
        let refreshTransport = TokenRefreshTransport(transport: transport, clock: clock)
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: refreshTransport,
            clock: clock,
        )

        async let first = renewer.validAccessSession()
        async let second = renewer.validAccessSession()
        async let third = renewer.validAccessSession()

        let results = await [first, second, third]

        #expect(transport.sentRequests().count == 1)
        for result in results {
            switch result {
            case .success(let session):
                #expect(session.accessToken == "new-access")
                #expect(session.refreshToken == "new-refresh")
            case .failure(let failure):
                Issue.record("Unexpected refresh failure \(failure)")
            }
        }
    }

    @Test
    func keepsSessionWhenRefreshNeverLeftDeviceOrGatewayReturned503() async throws {
        let clock = FakeAppClock()
        let initial = try makeSession(
            access: "access-1",
            refresh: "refresh-1",
            expiresAt: clock.now().addingTimeInterval(10),
        )
        let vault = FakeSessionVault(initial: .signedIn(initial))
        let transport = FakeHTTPTransport(
            responses: [
                .failure(
                    HTTPTransportError(
                        underlyingError: URLError(.notConnectedToInternet),
                        requestLeftDevice: false,
                        isCancelled: false,
                        isTimedOut: false,
                        requestId: "req-1",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 503,
                        headers: [:],
                        body: Data("upstream connect error".utf8),
                        requestId: "req-2",
                    )
                ),
            ]
        )
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )

        let offlineResult = await renewer.validAccessSession()
        #expect(offlineResult == .failure(.networkNotSent))
        #expect(vault.clearCount() == 0)

        let gateway503Result = await renewer.validAccessSession()
        #expect(gateway503Result == .failure(.serviceUnavailable))
        #expect(vault.clearCount() == 0)
    }

    @Test
    func clearsSessionWhenRefreshLeftDeviceAndTimedOutOrWasRefused() async throws {
        let clock = FakeAppClock()
        let initial = try makeSession(
            access: "access-1",
            refresh: "refresh-1",
            expiresAt: clock.now().addingTimeInterval(10),
        )
        let vault = FakeSessionVault(initial: .signedIn(initial))
        let transport = FakeHTTPTransport(
            responses: [
                .failure(
                    HTTPTransportError(
                        underlyingError: URLError(.timedOut),
                        requestLeftDevice: true,
                        isCancelled: false,
                        isTimedOut: true,
                        requestId: "req-timeout",
                    )
                )
            ]
        )
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )

        let result = await renewer.validAccessSession()

        #expect(result == .failure(.sessionExpired))
        #expect(vault.clearCount() == 1)
    }

    @Test
    func unreadableKeychainIsNeverClearedAndFirstLaunchSkipsLockedProtectedData() async {
        let clock = FakeAppClock()
        let vault = FakeSessionVault(initial: .unreadable)
        let transport = FakeHTTPTransport()
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )

        let result = await renewer.validAccessSession()
        #expect(result == .failure(.sessionUnavailable))
        #expect(vault.clearCount() == 0)
        #expect(transport.sentRequests().isEmpty)

        let markerStore = FakeFirstLaunchMarkerStore(completed: false)
        let protectedData = FakeProtectedDataStatusProvider(available: false)
        let cleaner = FirstLaunchSessionCleaner(
            vault: vault,
            markerStore: markerStore,
            protectedDataProvider: protectedData,
        )

        if case .failure(.sessionUnavailable) = cleaner.runOnForegroundActivation() {
            #expect(vault.clearCount() == 0)
        } else {
            Issue.record("Expected sessionUnavailable when protected data is locked")
        }

        #expect(!markerStore.hasCompletedFirstLaunch())

        protectedData.setAvailable(true)
        if case .success = cleaner.runOnForegroundActivation() {
            #expect(vault.clearCount() == 1)
        } else {
            Issue.record("Expected first-launch cleanup to succeed once unlocked")
        }

        #expect(markerStore.hasCompletedFirstLaunch())
    }

    private func makeSession(
        access: String,
        refresh: String,
        expiresAt: Date,
    ) throws -> AuthSession {
        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        return AuthSession(
            accessToken: access,
            refreshToken: refresh,
            expiresAt: expiresAt,
            user: UserIdentity(
                accountId: accountId,
                principalId: principalId,
                email: "buyer@example.test",
                role: .customer,
            ),
        )
    }
}
