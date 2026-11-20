import Foundation

public struct OutboxDrainResult: Sendable, Equatable {
    public let syncedCount: Int
    public let retryLaterCount: Int
    public let permanentFailureCount: Int

    public init(
        syncedCount: Int,
        retryLaterCount: Int,
        permanentFailureCount: Int,
    ) {
        self.syncedCount = syncedCount
        self.retryLaterCount = retryLaterCount
        self.permanentFailureCount = permanentFailureCount
    }
}
