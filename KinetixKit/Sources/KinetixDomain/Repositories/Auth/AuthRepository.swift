import Foundation

public protocol AuthRepository: Sendable {
    func signIn(
        email: String,
        password: String,
    ) async -> Result<SignInOutcome, Failure>

    func register(
        email: String,
        password: String,
    ) async -> Result<AuthSession, Failure>

    func verifyTwoFactor(
        challengeToken: String,
        code: String,
    ) async -> Result<AuthSession, Failure>

    func signOut() async -> Result<Void, Failure>
}
