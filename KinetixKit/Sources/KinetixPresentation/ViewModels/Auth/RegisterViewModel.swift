import Foundation
import KinetixDomain
import Observation

@Observable
public final class RegisterViewModel {
    public var email: String = ""
    public var password: String = ""
    public private(set) var state: RegisterState = .idle

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

    public var isPasswordLengthValid: Bool {
        password.count >= 12 && password.utf8.count <= 72
    }

    public var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty && trimmedEmail.count <= 254 else {
            return false
        }

        guard isPasswordLengthValid else {
            return false
        }

        switch state {
        case .submitting, .rateLimited:
            return false
        case .idle, .failed, .registered:
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
            await performRegistration(email: submittedEmail, password: submittedPassword)
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func performRegistration(
        email: String,
        password: String,
    ) async {
        let result = await authRepository.register(email: email, password: password)
        switch result {
        case .success(let session):
            self.password = ""
            state = .registered(session)
        case .failure(.cancelled):
            state = .idle
        case .failure(.rateLimited(let rateLimit)):
            await runCountdown(seconds: rateLimit.retryAfterSeconds)
        case .failure(let failure):
            state = .failed(failure)
        }
    }

    private func runCountdown(seconds: Int) async {
        var remaining = max(1, seconds)
        while remaining > 0 {
            state = .rateLimited(secondsRemaining: remaining)

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
