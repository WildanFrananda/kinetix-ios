import Foundation
import KinetixDomain
import KinetixFakes
import KinetixPresentation
import Testing

struct AuthViewModelsTests {
    @Test
    func signInAllowsSixCharPasswordAndRunsSignInDelayedCountdownWithFakeClock() async {
        let authRepo = FakeAuthRepository()
        authRepo.setSignInResult(
            .failure(.rateLimited(RateLimitFailure(retryAfterSeconds: 3, isSignInDelayed: true)))
        )
        let clock = FakeAppClock()
        let viewModel = SignInViewModel(authRepository: authRepo, clock: clock)

        viewModel.email = "buyer@example.test"
        viewModel.password = "123456"
        #expect(viewModel.canSubmit)

        viewModel.submit()
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(30))

        #expect(clock.sleptDurations().count == 3)
        #expect(viewModel.state == .idle)
    }

    @Test
    func registerEnforcesTwelveCharacterMinimumAnd72UTF8ByteMaximum() {
        let viewModel = RegisterViewModel(
            authRepository: FakeAuthRepository(),
            clock: FakeAppClock(),
        )
        viewModel.email = "buyer@example.test"

        viewModel.password = "short11char"
        #expect(!viewModel.canSubmit)

        viewModel.password = "twelve12char"
        #expect(viewModel.canSubmit)

        viewModel.password = String(repeating: "a", count: 73)
        #expect(!viewModel.canSubmit)
    }

    @Test
    func twoFactorChallengeKeepsOpenOnWrongCodeAndClosesOnExhausted() async {
        let challenge = TwoFactorChallenge(
            challengeToken: "chal-token",
            expiresAt: Date(timeIntervalSince1970: 1_760_000_300),
            hasPasskeys: false,
        )
        let authRepo = FakeAuthRepository()
        let viewModel = TwoFactorChallengeViewModel(
            challenge: challenge,
            authRepository: authRepo,
            clock: FakeAppClock(),
        )

        authRepo.setVerifyResult(.failure(.unauthorized(UnauthorizedFailure(code: "WRONG_CODE"))))
        viewModel.code = "123456"
        viewModel.submit()
        try? await Task.sleep(for: .milliseconds(20))

        #expect(viewModel.state == .wrongCode)

        authRepo.setVerifyResult(
            .failure(.unauthorized(UnauthorizedFailure(code: "CHALLENGE_EXHAUSTED")))
        )
        viewModel.code = "654321"
        viewModel.submit()
        try? await Task.sleep(for: .milliseconds(20))

        #expect(viewModel.state == .challengeClosed)
    }

    @Test
    func twoFactorSettingsClearsPasswordAfterWrongPasswordFailure() async throws {
        let accountId = try #require(AccountId(42))
        let repo = FakeTwoFactorRepository()
        repo.setSetupResult(.failure(.unauthorized(UnauthorizedFailure(code: "Unauthorized"))))
        let viewModel = TwoFactorSettingsViewModel(
            accountId: accountId,
            repository: repo,
            clock: FakeAppClock(),
        )

        viewModel.password = "wrong-pass"
        viewModel.requestSetup()
        try? await Task.sleep(for: .milliseconds(20))

        #expect(viewModel.password.isEmpty)
        #expect(
            viewModel.state == .failed(.unauthorized(UnauthorizedFailure(code: "Unauthorized")))
        )
    }
}
