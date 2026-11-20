import Foundation
import KinetixDomain

public struct DefaultTwoFactorRepository: TwoFactorRepository {
    private let apiClient: IdentityAPIClient

    public init(apiClient: IdentityAPIClient) {
        self.apiClient = apiClient
    }

    public func setup(
        accountId: AccountId,
        password: String,
    ) async -> Result<TwoFactorSetup, Failure> {
        return await apiClient.setupTwoFactor(accountId: accountId, password: password)
    }

    public func enable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        return await apiClient.enableTwoFactor(
            accountId: accountId,
            code: code,
            password: password,
        )
    }

    public func disable(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        return await apiClient.disableTwoFactor(
            accountId: accountId,
            code: code,
            password: password,
        )
    }
}
