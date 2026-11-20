import Foundation

public protocol SessionRepository: Sendable {
    func readStoredSession() async -> Result<StoredSessionState, Failure>
    func restoreAndVerifySession() async -> Result<AuthSession?, Failure>
    func clearLocalSession() async -> Result<Void, Failure>
    func handleFirstLaunchCleanupIfNeeded() async -> Result<Void, Failure>
    func drainPendingOutbox() async -> Result<Int, Failure>
}
