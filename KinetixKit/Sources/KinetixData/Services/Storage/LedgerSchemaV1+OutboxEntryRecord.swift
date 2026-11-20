import Foundation
import SwiftData

extension LedgerSchemaV1 {
    @Model
    public final class OutboxEntryRecord {
        #Unique<OutboxEntryRecord>([\.dedupeKey])

        public var dedupeKey: String
        public var principalId: String
        public var accountId: Int
        public var operationKind: String
        public var payloadData: Data
        public var statusRaw: String
        public var attemptCount: Int
        public var nextAttemptAt: Date
        public var createdAt: Date
        public var updatedAt: Date
        public var lastError: String?

        public init(
            dedupeKey: String,
            principalId: String,
            accountId: Int,
            operationKind: String,
            payloadData: Data,
            statusRaw: String,
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
            self.statusRaw = statusRaw
            self.attemptCount = attemptCount
            self.nextAttemptAt = nextAttemptAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.lastError = lastError
        }
    }
}
