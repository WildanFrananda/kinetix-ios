import Foundation

public protocol TwoFactorRepository: Sendable {
    func setup(
        accountId: AccountId,
        password: String,
    ) async -> Result<TwoFactorSetup, Failure>

    func enable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure>

    func disable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure>
}
