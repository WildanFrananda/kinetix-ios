import Foundation
import KinetixDomain
import Observation

@Observable
public final class TwoFactorSettingsViewModel {
    public var password: String = ""
    public var code: String = ""
    public private(set) var state: TwoFactorSettingsState = .idle

    private let accountId: AccountId
    private let repository: any TwoFactorRepository
    private let clock: any AppClock
    private var activeTask: Task<Void, Never>?

    public init(
        accountId: AccountId,
        repository: any TwoFactorRepository,
        clock: any AppClock,
    ) {
        self.accountId = accountId
        self.repository = repository
        self.clock = clock
    }

    public func requestSetup() {
        let submittedPassword = password
        guard !submittedPassword.isEmpty else {
            return
        }

        activeTask?.cancel()
        state = .submitting
        activeTask = Task {
            let result = await repository.setup(
                accountId: accountId,
                password: submittedPassword,
            )
            self.password = ""
            switch result {
            case .success(let setup):
                state = .setupReady(setup)
            case .failure(.cancelled):
                state = .idle
            case .failure(.conflict):
                state = .alreadyEnabled
            case .failure(.rateLimited(let rateLimit)):
                await runCountdown(
                    seconds: rateLimit.retryAfterSeconds,
                    isSignInDelayed: rateLimit.isSignInDelayed,
                )
            case .failure(let failure):
                state = .failed(failure)
            }
        }
    }

    public func confirmEnable() {
        let submittedPassword = password
        let submittedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPassword.isEmpty && submittedCode.count == 6 else {
            return
        }

        activeTask?.cancel()
        state = .submitting
        activeTask = Task {
            let result = await repository.enable(
                accountId: accountId,
                code: submittedCode,
                password: submittedPassword,
            )
            self.password = ""
            self.code = ""
            switch result {
            case .success:
                state = .enabled
            case .failure(.cancelled):
                state = .idle
            case .failure(.unprocessable):
                state = .invalidCode
            case .failure(.rateLimited(let rateLimit)):
                await runCountdown(
                    seconds: rateLimit.retryAfterSeconds,
                    isSignInDelayed: rateLimit.isSignInDelayed,
                )
            case .failure(let failure):
                state = .failed(failure)
            }
        }
    }

    public func disableTwoFactor() {
        let submittedPassword = password
        let submittedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPassword.isEmpty && submittedCode.count == 6 else {
            return
        }

        activeTask?.cancel()
        state = .submitting
        activeTask = Task {
            let result = await repository.disable(
                accountId: accountId,
                code: submittedCode,
                password: submittedPassword,
            )
            self.password = ""
            self.code = ""
            switch result {
            case .success:
                state = .disabled
            case .failure(.cancelled):
                state = .idle
            case .failure(.conflict):
                state = .notEnabled
            case .failure(.unprocessable):
                state = .invalidCode
            case .failure(.rateLimited(let rateLimit)):
                await runCountdown(
                    seconds: rateLimit.retryAfterSeconds,
                    isSignInDelayed: rateLimit.isSignInDelayed,
                )
            case .failure(let failure):
                state = .failed(failure)
            }
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
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
