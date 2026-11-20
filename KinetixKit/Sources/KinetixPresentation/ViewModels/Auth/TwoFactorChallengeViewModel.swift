import Foundation
import KinetixDomain
import Observation

@Observable
public final class TwoFactorChallengeViewModel {
    public var code: String = ""
    public private(set) var state: TwoFactorChallengeState = .idle
    public let challenge: TwoFactorChallenge

    private let authRepository: any AuthRepository
    private let clock: any AppClock
    private var activeTask: Task<Void, Never>?

    public init(
        challenge: TwoFactorChallenge,
        authRepository: any AuthRepository,
        clock: any AppClock,
    ) {
        self.challenge = challenge
        self.authRepository = authRepository
        self.clock = clock
    }

    public var canSubmit: Bool {
        let digitsOnly = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard digitsOnly.count == 6 && digitsOnly.allSatisfy(\.isNumber) else {
            return false
        }

        switch state {
        case .submitting, .rateLimited, .challengeClosed:
            return false
        case .idle, .wrongCode, .failed, .verified:
            return true
        }
    }

    public func submit() {
        guard canSubmit else {
            return
        }

        let submittedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        activeTask?.cancel()
        state = .submitting
        activeTask = Task {
            await performVerify(code: submittedCode)
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func performVerify(code: String) async {
        let result = await authRepository.verifyTwoFactor(
            challengeToken: challenge.challengeToken,
            code: code,
        )
        switch result {
        case .success(let session):
            self.code = ""
            state = .verified(session)
        case .failure(.cancelled):
            state = .idle
        case .failure(.rateLimited(let rateLimit)):
            await runCountdown(
                seconds: rateLimit.retryAfterSeconds,
                isSignInDelayed: rateLimit.isSignInDelayed,
            )
        case .failure(.unauthorized(let unauthorized)):
            self.code = ""
            switch unauthorized.code {
            case "WRONG_CODE":
                state = .wrongCode
            case "CHALLENGE_EXHAUSTED", "CHALLENGE_SPENT", "CHALLENGE_INVALID":
                state = .challengeClosed
            default:
                state = .failed(.unauthorized(unauthorized))
            }
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
