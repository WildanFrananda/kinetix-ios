import Foundation
import KinetixData
import KinetixDomain
import KinetixFakes
import Testing

struct ProfileAndOutboxTests {
    @Test
    func offlinePhoneEditThenAddressEditMergesIntoSinglePutPayload() async throws {
        let clock = FakeAppClock()
        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let session = makeSession(accountId: accountId, principalId: principalId, clock: clock)
        let vault = FakeSessionVault(initial: .signedIn(session))
        let cacheStore = FakeProfileCacheStore()
        let outboxStore = FakeOutboxStore()
        let analytics = FakeAnalyticsTracker()
        let crash = FakeCrashReporter()

        let confirmed = DeliveryProfile(
            id: 17,
            accountId: accountId,
            fullName: "Siti Rahmawati",
            phoneNumber: "+6281200000001",
            streetAddress: "Jalan Lama No. 1",
            city: "Jakarta",
            postalCode: "12730",
            avatarURL: "https://cdn.example.test/old.jpg",
        )
        _ = await cacheStore.saveProfile(confirmed, principalId: principalId, savedAt: clock.now())

        let offlineError = Result<HTTPResponse, HTTPTransportError>.failure(
            HTTPTransportError(
                underlyingError: URLError(.notConnectedToInternet),
                requestLeftDevice: false,
                isCancelled: false,
                isTimedOut: false,
                requestId: "r-off",
            )
        )
        let savedProfileJSON = Data(
            """
            {
              "id": 17,
              "userId": 42,
              "fullName": "Siti Rahmawati",
              "phoneNumber": "+6281299999999",
              "streetAddress": "Jalan Baru No. 99",
              "city": "Jakarta",
              "postalCode": "12730",
              "avatarUrl": null
            }
            """.utf8
        )
        let transport = FakeHTTPTransport(
            responses: [
                offlineError,
                offlineError,
                .success(
                    HTTPResponse(
                        statusCode: 200,
                        headers: [:],
                        body: savedProfileJSON,
                        requestId: "r-drain",
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
        let executor = ProfileOutboxExecutor(
            apiClient: apiClient,
            cacheStore: cacheStore,
            clock: clock,
        )
        let processor = OutboxProcessor(
            outboxStore: outboxStore,
            executor: executor,
            clock: clock,
            analyticsTracker: analytics,
            crashReporter: crash,
        )
        let repository = DefaultProfileRepository(
            apiClient: apiClient,
            cacheStore: cacheStore,
            outboxProcessor: processor,
            outboxStore: outboxStore,
            clock: clock,
        )

        var firstDraft = ProfileDraft(profile: confirmed)
        firstDraft.phoneNumber = "+6281299999999"
        firstDraft.avatarURL = ""
        let firstSave = await repository.saveProfile(
            accountId: accountId,
            principalId: principalId,
            draft: firstDraft,
        )
        if case .success(.queuedOffline(let queued)) = firstSave {
            #expect(queued.phoneNumber == "+6281299999999")
            #expect(queued.avatarURL == nil)
        } else {
            Issue.record("Expected queuedOffline, got \(firstSave)")
        }

        var secondDraft = ProfileDraft(profile: confirmed)
        secondDraft.streetAddress = "Jalan Baru No. 99"
        secondDraft.avatarURL = "https://cdn.example.test/old.jpg"
        let secondSave = await repository.saveProfile(
            accountId: accountId,
            principalId: principalId,
            draft: secondDraft,
        )
        if case .success(.queuedOffline(let queued)) = secondSave {
            #expect(queued.phoneNumber == "+6281299999999")
            #expect(queued.streetAddress == "Jalan Baru No. 99")
            #expect(queued.avatarURL == nil)
        } else {
            Issue.record("Expected merged queuedOffline, got \(secondSave)")
        }

        let drainResult = await processor.drain(for: principalId)
        #expect(
            drainResult
                == .success(
                    OutboxDrainResult(
                        syncedCount: 1,
                        retryLaterCount: 0,
                        permanentFailureCount: 0,
                    )
                )
        )
        #expect(analytics.eventNames() == ["outbox_entry_synced"])

        let lastBody = try #require(transport.sentRequests().last?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: lastBody) as? [String: Any])
        #expect(json["phoneNumber"] as? String == "+6281299999999")
        #expect(json["streetAddress"] as? String == "Jalan Baru No. 99")
        #expect(json["avatarUrl"] is NSNull)
        #expect(json["fullName"] == nil)
    }

    @Test
    func outboxIsolatesEntriesPerPrincipalAndEnforcesBackoffWithFakeClock() async throws {
        let clock = FakeAppClock()
        let principalA = try #require(PrincipalId("11111111-1111-4111-8111-111111111111"))
        let principalB = try #require(PrincipalId("22222222-2222-4222-8222-222222222222"))
        let accountA = try #require(AccountId(10))

        let outboxStore = FakeOutboxStore()
        let executor = FakeOutboxExecutor(
            results: [
                .failure(.serviceUnavailable),
                .failure(
                    .rateLimited(RateLimitFailure(retryAfterSeconds: 45, isSignInDelayed: false))
                ),
                .success(()),
            ]
        )
        let processor = OutboxProcessor(
            outboxStore: outboxStore,
            executor: executor,
            clock: clock,
            analyticsTracker: FakeAnalyticsTracker(),
            crashReporter: FakeCrashReporter(),
        )

        _ = await processor.enqueueProfilePatch(
            ProfilePatch(phoneNumber: "+628111111111"),
            accountId: accountA,
            principalId: principalA,
        )

        let drainAsB = await processor.drain(for: principalB)
        #expect(
            drainAsB
                == .success(
                    OutboxDrainResult(syncedCount: 0, retryLaterCount: 0, permanentFailureCount: 0)
                )
        )
        #expect(executor.executedKeys().isEmpty)

        let firstTryA = await processor.drain(for: principalA)
        #expect(
            firstTryA
                == .success(
                    OutboxDrainResult(syncedCount: 0, retryLaterCount: 1, permanentFailureCount: 0)
                )
        )

        clock.advance(by: 14)
        let tooEarly = await processor.drain(for: principalA)
        #expect(
            tooEarly
                == .success(
                    OutboxDrainResult(syncedCount: 0, retryLaterCount: 0, permanentFailureCount: 0)
                )
        )

        clock.advance(by: 1)
        let secondTryA = await processor.drain(for: principalA)
        #expect(
            secondTryA
                == .success(
                    OutboxDrainResult(syncedCount: 0, retryLaterCount: 1, permanentFailureCount: 0)
                )
        )

        clock.advance(by: 44)
        let beforeRetryAfter = await processor.drain(for: principalA)
        #expect(
            beforeRetryAfter
                == .success(
                    OutboxDrainResult(syncedCount: 0, retryLaterCount: 0, permanentFailureCount: 0)
                )
        )

        clock.advance(by: 1)
        let thirdTryA = await processor.drain(for: principalA)
        #expect(
            thirdTryA
                == .success(
                    OutboxDrainResult(syncedCount: 1, retryLaterCount: 0, permanentFailureCount: 0)
                )
        )
    }

    @Test
    func profile404ReturnsNotCreatedAnd504SettlesByReadingProfile() async throws {
        let clock = FakeAppClock()
        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let session = makeSession(accountId: accountId, principalId: principalId, clock: clock)
        let vault = FakeSessionVault(initial: .signedIn(session))
        let cacheStore = FakeProfileCacheStore()
        let outboxStore = FakeOutboxStore()

        let settledJSON = Data(
            """
            {
              "id": 17,
              "userId": 42,
              "fullName": "Budi",
              "phoneNumber": "+628123456789",
              "streetAddress": "Jl. Sudirman 1",
              "city": "Jakarta",
              "postalCode": "10220"
            }
            """.utf8
        )
        let transport = FakeHTTPTransport(
            responses: [
                .success(
                    HTTPResponse(
                        statusCode: 404,
                        headers: [:],
                        body: Data(#"{"error":"Not Found","statusCode":404}"#.utf8),
                        requestId: "r-404",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 504,
                        headers: [:],
                        body: Data("upstream request timeout".utf8),
                        requestId: "r-504",
                    )
                ),
                .success(
                    HTTPResponse(
                        statusCode: 200,
                        headers: [:],
                        body: settledJSON,
                        requestId: "r-settle",
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
        let processor = OutboxProcessor(
            outboxStore: outboxStore,
            executor: ProfileOutboxExecutor(
                apiClient: apiClient,
                cacheStore: cacheStore,
                clock: clock,
            ),
            clock: clock,
            analyticsTracker: FakeAnalyticsTracker(),
            crashReporter: FakeCrashReporter(),
        )
        let repo = DefaultProfileRepository(
            apiClient: apiClient,
            cacheStore: cacheStore,
            outboxProcessor: processor,
            outboxStore: outboxStore,
            clock: clock,
        )

        let initialFetch = await repo.fetchProfile(accountId: accountId, principalId: principalId)
        #expect(initialFetch == .success(.notCreated))

        let draft = ProfileDraft(
            fullName: "Budi",
            phoneNumber: "+628123456789",
            streetAddress: "Jl. Sudirman 1",
            city: "Jakarta",
            postalCode: "10220",
        )
        let saveAfter504 = await repo.saveProfile(
            accountId: accountId,
            principalId: principalId,
            draft: draft,
        )
        if case .success(.confirmed(let profile)) = saveAfter504 {
            #expect(profile.fullName == "Budi")
            #expect(profile.streetAddress == "Jl. Sudirman 1")
        } else {
            Issue.record("Expected 504 to settle as confirmed via read, got \(saveAfter504)")
        }
    }

    private func makeSession(
        accountId: AccountId,
        principalId: PrincipalId,
        clock: FakeAppClock,
    ) -> AuthSession {
        return AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: clock.now().addingTimeInterval(600),
            user: UserIdentity(
                accountId: accountId,
                principalId: principalId,
                email: "buyer@example.test",
                role: .customer,
            ),
        )
    }
}
