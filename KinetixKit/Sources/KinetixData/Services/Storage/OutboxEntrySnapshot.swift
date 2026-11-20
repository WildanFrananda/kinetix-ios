import Foundation
import KinetixDomain

public struct OutboxEntrySnapshot: Sendable, Equatable {
    public let dedupeKey: String
    public let principalId: PrincipalId
    public let accountId: AccountId
    public let operationKind: OutboxOperationKind
    public let payloadData: Data
    public let status: OutboxEntryStatus
    public let attemptCount: Int
    public let nextAttemptAt: Date
    public let createdAt: Date
    public let updatedAt: Date
    public let lastError: String?

    public init(
        dedupeKey: String,
        principalId: PrincipalId,
        accountId: AccountId,
        operationKind: OutboxOperationKind,
        payloadData: Data,
        status: OutboxEntryStatus,
        attemptCount: Int,
        nextAttemptAt: Date,
        createdAt: Date,
        updatedAt: Date,
        lastError: String?,
    ) {
        self.dedupeKey = dedupeKey
        self.principalId = principalId
        self.accountId = accountId
        self.operationKind = operationKind
        self.payloadData = payloadData
        self.status = status
        self.attemptCount = attemptCount
        self.nextAttemptAt = nextAttemptAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastError = lastError
    }
}
