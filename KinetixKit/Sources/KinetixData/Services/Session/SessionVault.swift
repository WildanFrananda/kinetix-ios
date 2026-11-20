import Foundation
import KinetixDomain

public protocol SessionVault: Sendable {
    func read() -> StoredSessionState
    func write(_ session: AuthSession) -> Result<Void, Failure>
    func clear() -> Result<Void, Failure>
}
