import Foundation
import KinetixDomain
import Synchronization

public final class FakeAuthRepository: AuthRepository {
    private let state = Mutex<
        (
            signInResult: Result<SignInOutcome, Failure>,
            registerResult: Result<AuthSession, Failure>,
            verifyResult: Result<AuthSession, Failure>,
            signOutCount: Int,
        )
    >(
        (
            signInResult: .failure(.networkNotSent),
            registerResult: .failure(.networkNotSent),
            verifyResult: .failure(.networkNotSent),
            signOutCount: 0,
        )
    )

    public init() {}

    public func setSignInResult(_ result: Result<SignInOutcome, Failure>) {
        state.withLock { $0.signInResult = result }
    }

    public func setRegisterResult(_ result: Result<AuthSession, Failure>) {
        state.withLock { $0.registerResult = result }
    }

    public func setVerifyResult(_ result: Result<AuthSession, Failure>) {
        state.withLock { $0.verifyResult = result }
    }

    public func signOutCount() -> Int {
        return state.withLock { $0.signOutCount }
    }

    public func signIn(
        email: String,
        password: String,
    ) async -> Result<SignInOutcome, Failure> {
        return state.withLock { $0.signInResult }
    }

    public func register(
        email: String,
        password: String,
    ) async -> Result<AuthSession, Failure> {
        return state.withLock { $0.registerResult }
    }

    public func verifyTwoFactor(
        challengeToken: String,
        code: String,
    ) async -> Result<AuthSession, Failure> {
        return state.withLock { $0.verifyResult }
    }

    public func signOut() async -> Result<Void, Failure> {
        state.withLock { $0.signOutCount += 1 }
        return .success(())
    }
}
