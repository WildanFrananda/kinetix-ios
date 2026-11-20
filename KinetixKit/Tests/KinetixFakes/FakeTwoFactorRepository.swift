import Foundation
import KinetixDomain
import Synchronization

public final class FakeTwoFactorRepository: TwoFactorRepository {
    private let state = Mutex<
        (
            setupResult: Result<TwoFactorSetup, Failure>,
            enableResult: Result<TwoFactorStatus, Failure>,
            disableResult: Result<TwoFactorStatus, Failure>,
        )
    >(
        (
            setupResult: .failure(.networkNotSent),
            enableResult: .failure(.networkNotSent),
            disableResult: .failure(.networkNotSent),
        )
    )

    public init() {}

    public func setSetupResult(_ result: Result<TwoFactorSetup, Failure>) {
        state.withLock { $0.setupResult = result }
    }

    public func setEnableResult(_ result: Result<TwoFactorStatus, Failure>) {
        state.withLock { $0.enableResult = result }
    }

    public func setDisableResult(_ result: Result<TwoFactorStatus, Failure>) {
        state.withLock { $0.disableResult = result }
    }

    public func setup(
        accountId: AccountId,
        password: String,
    ) async -> Result<TwoFactorSetup, Failure> {
        return state.withLock { $0.setupResult }
    }

    public func enable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        return state.withLock { $0.enableResult }
    }

    public func disable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        return state.withLock { $0.disableResult }
    }
}
