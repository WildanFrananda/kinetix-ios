import Foundation
import KinetixDomain

public protocol OutboxExecutor: Sendable {
    func execute(_ entry: OutboxEntrySnapshot) async -> Result<Void, Failure>
}
