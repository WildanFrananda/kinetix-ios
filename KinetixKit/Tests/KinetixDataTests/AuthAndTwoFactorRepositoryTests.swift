import Foundation
import KinetixData
import KinetixDomain
import KinetixFakes
import Testing

struct AuthAndTwoFactorRepositoryTests {
    @Test
    func signInHandlesBuyerSessionMfaChallengeAndRefusesNonCustomerOrEnrolment() async throws {
        let clock = FakeAppClock()
        let vault = FakeSessionVault()
        let cache = FakeProfileCacheStore()
        let routes = FakeRoutePersistenceStore()
        let analytics = FakeAnalyticsTracker()
        let crash = FakeCrashReporter()

        let challengeJSON = Data(
            """
            {
              "mfaRequired": true,
              "challengeToken": "chal-1",
              "expiresIn": 300,
              "passkeys": false
            }
            """.utf8
        )
        let adminEnrolmentJSON = Data(
            """
            {
              "mfaEnrolmentRequired": true,
              "enrolmentToken": "enrol-1",
              "tokenType": "Bearer",
              "expiresIn": 600,
              "userId": 3
            }
            """.utf8
        )
        let merchantSessionJSON = Data(
            """
            {
              "accessToken": "m-access",
              "refreshToken": "m-refresh",
              "expiresIn": 900,
              "tokenType": "Bearer",
              "user": {
                "id": 7,
                "email": "seller@example.test",
                "role": "merchant",
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
                        body: challengeJSON,
                        requestId: "r1",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 200,
                        headers: [:],
                        body: adminEnrolmentJSON,
                        requestId: "r2",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 200,
                        headers: [:],
                        body: merchantSessionJSON,
                        requestId: "r3",
                    )
                ),
            ]
        )
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )
        let apiClient = IdentityAPIClient(
            apiCaller: SafeApiCaller(transport: transport, sessionRenewer: renewer),
            clock: clock,
        )
        let repo = DefaultAuthRepository(
            apiClient: apiClient,
            vault: vault,
            cacheStore: cache,
            routeStore: routes,
            analyticsTracker: analytics,
            crashReporter: crash,
        )

        let first = await repo.signIn(email: "buyer@example.test", password: "secret")
        if case .success(.twoFactorRequired(let challenge)) = first {
            #expect(challenge.challengeToken == "chal-1")
        } else {
            Issue.record("Expected twoFactorRequired, got \(first)")
        }

        let second = await repo.signIn(email: "admin@example.test", password: "secret")
        #expect(second == .failure(.unsupportedAccountRole))
        #expect(vault.writeCount() == 0)

        let third = await repo.signIn(email: "seller@example.test", password: "secret")
        #expect(third == .failure(.unsupportedAccountRole))
        #expect(vault.writeCount() == 0)
    }

    @Test
    func twoFactorWrongPassword401KeepsSessionAndNeverTriggersRefresh() async throws {
        let clock = FakeAppClock()
        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let session = AuthSession(
            accessToken: "valid-access",
            refreshToken: "valid-refresh",
            expiresAt: clock.now().addingTimeInterval(600),
            user: UserIdentity(
                accountId: accountId,
                principalId: principalId,
                email: "buyer@example.test",
                role: .customer,
            ),
        )
        let vault = FakeSessionVault(initial: .signedIn(session))
        let wrongPasswordJSON = Data(
            #"{"message":"Invalid email or password credentials","error":"Unauthorized","statusCode":401}"#
                .utf8
        )
        let transport = FakeHTTPTransport(
            responses: [
                .success(
                    HTTPResponse(
                        statusCode: 401,
                        headers: [:],
                        body: wrongPasswordJSON,
                        requestId: "r-2fa",
                    )
                )
            ]
        )
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )
        let apiClient = IdentityAPIClient(
            apiCaller: SafeApiCaller(transport: transport, sessionRenewer: renewer),
            clock: clock,
        )
        let repo = DefaultTwoFactorRepository(apiClient: apiClient)

        let result = await repo.disable(
            accountId: accountId,
            code: "123456",
            password: "wrong-password",
        )

        #expect(result == .failure(.unauthorized(UnauthorizedFailure(code: "Unauthorized"))))
        #expect(vault.clearCount() == 0)
        #expect(transport.sentRequests().count == 1)
    }

    @Test
    func verifyTwoFactorDistinguishesWrongCodeFromSpentChallenge() async {
        let clock = FakeAppClock()
        let vault = FakeSessionVault()
        let wrongCodeJSON = Data(#"{"error":"WRONG_CODE","message":"bad"}"#.utf8)
        let exhaustedJSON = Data(#"{"error":"CHALLENGE_EXHAUSTED","message":"done"}"#.utf8)
        let transport = FakeHTTPTransport(
            responses: [
                .success(
                    HTTPResponse(
                        statusCode: 401,
                        headers: [:],
                        body: wrongCodeJSON,
                        requestId: "r1",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 401,
                        headers: [:],
                        body: exhaustedJSON,
                        requestId: "r2",
                    )
                ),
            ]
        )
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: TokenRefreshTransport(transport: transport, clock: clock),
            clock: clock,
        )
        let repo = DefaultAuthRepository(
            apiClient: IdentityAPIClient(
                apiCaller: SafeApiCaller(transport: transport, sessionRenewer: renewer),
                clock: clock,
            ),
            vault: vault,
            cacheStore: FakeProfileCacheStore(),
            routeStore: FakeRoutePersistenceStore(),
            analyticsTracker: FakeAnalyticsTracker(),
            crashReporter: FakeCrashReporter(),
        )

        let wrongCode = await repo.verifyTwoFactor(challengeToken: "chal", code: "111111")
        #expect(wrongCode == .failure(.unauthorized(UnauthorizedFailure(code: "WRONG_CODE"))))

        let exhausted = await repo.verifyTwoFactor(challengeToken: "chal", code: "222222")
        #expect(
            exhausted == .failure(.unauthorized(UnauthorizedFailure(code: "CHALLENGE_EXHAUSTED")))
        )
    }
}
