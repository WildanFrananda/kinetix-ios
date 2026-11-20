import Foundation
import KinetixDomain
import Observation

@Observable
public final class SignInViewModel {
    public var email: String = ""
    public var password: String = ""
    public private(set) var state: SignInState = .idle

    private let authRepository: any AuthRepository
    private let clock: any AppClock
    private var activeTask: Task<Void, Never>?

    public init(
        authRepository: any AuthRepository,
        clock: any AppClock,
    ) {
        self.authRepository = authRepository
        self.clock = clock
    }

    public var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty && trimmedEmail.count <= 254 else {
            return false
        }

        guard password.count >= 6 && password.count <= 1024 else {
            return false
        }

        switch state {
        case .submitting, .rateLimited:
            return false
        case .idle, .failed, .signedIn, .twoFactorRequired:
            return true
        }
    }

    public func submit() {
        guard canSubmit else {
            return
        }

        let submittedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let submittedPassword = password

        activeTask?.cancel()
        state = .submitting
        activeTask = Task {
            await performSignIn(email: submittedEmail, password: submittedPassword)
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func performSignIn(
        email: String,
        password: String,
    ) async {
        let result = await authRepository.signIn(email: email, password: password)
        switch result {
        case .success(.signedIn(let session)):
            self.password = ""
            state = .signedIn(session)
        case .success(.twoFactorRequired(let challenge)):
            self.password = ""
            state = .twoFactorRequired(challenge)
        case .failure(.cancelled):
            state = .idle
        case .failure(.rateLimited(let rateLimit)):
            await runCountdown(
                seconds: rateLimit.retryAfterSeconds,
                isSignInDelayed: rateLimit.isSignInDelayed,
            )
        case .failure(let failure):
            state = .failed(failure)
        }
    }

    private func runCountdown(
        seconds: Int,
        isSignInDelayed: Bool,
    ) async {
        var remaining = max(1, seconds)
        while remaining > 0 {
            state = .rateLimited(
                secondsRemaining: remaining,
                isSignInDelayed: isSignInDelayed,
            )

            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                return
            }

            remaining -= 1
        }

        state = .idle
    }
}
