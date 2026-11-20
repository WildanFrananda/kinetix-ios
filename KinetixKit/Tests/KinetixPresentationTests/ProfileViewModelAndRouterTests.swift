import Foundation
import KinetixDomain
import KinetixFakes
import KinetixPresentation
import Testing

struct ProfileViewModelAndRouterTests {
    @Test
    func profileViewModelLoadsOnceOnStartAndReloadsOnExplicitRefresh() async throws {
        let accountId = try #require(AccountId(42))
        let principalId = try #require(PrincipalId("0f8b6c1e-5a2d-4c3b-9e7f-1a2b3c4d5e6f"))
        let profile = DeliveryProfile(
            id: 1,
            accountId: accountId,
            fullName: "Siti",
            phoneNumber: "+628123456789",
            streetAddress: "Jl. Kenanga",
            city: "Jakarta",
            postalCode: "12730",
        )
        let repo = FakeProfileRepository()
        repo.setFetchResult(.success(.confirmed(profile)))
        let viewModel = ProfileViewModel(
            accountId: accountId,
            principalId: principalId,
            repository: repo,
        )

        #expect(viewModel.state == .idle)

        viewModel.start()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(viewModel.state == .loaded(profile))
        #expect(repo.fetchCount() == 1)

        viewModel.start()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(repo.fetchCount() == 1)

        viewModel.refresh()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(repo.fetchCount() == 2)
    }

    @Test
    func appRouterDefersProtectedRouteUntilSignInAndIsolatesPersistedPathsByPrincipal() throws {
        let principalA = try #require(PrincipalId("11111111-1111-4111-8111-111111111111"))
        let principalB = try #require(PrincipalId("22222222-2222-4222-8222-222222222222"))
        let store = FakeRoutePersistenceStore()
        let router = AppRouter(persistenceStore: store)

        router.navigate(to: .profile, isAuthenticated: false)
        #expect(router.path.isEmpty)
        #expect(router.pendingSessionRoute == .profile)

        router.restoreSession(for: principalA)
        #expect(router.path == [.profile])

        let restoredRouterA = AppRouter(persistenceStore: store)
        restoredRouterA.restoreSession(for: principalA)
        #expect(restoredRouterA.path == [.profile])

        let restoredRouterB = AppRouter(persistenceStore: store)
        restoredRouterB.restoreSession(for: principalB)
        #expect(restoredRouterB.path.isEmpty)

        router.clearSession(for: principalA)
        #expect(router.path.isEmpty)
        #expect(store.loadEncodedPath(for: principalA) == nil)
    }
}
