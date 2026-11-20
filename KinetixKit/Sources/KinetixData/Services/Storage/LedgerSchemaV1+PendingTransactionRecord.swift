import Foundation
import SwiftData

extension LedgerSchemaV1 {
    @Model
    public final class PendingTransactionRecord {
        #Unique<PendingTransactionRecord>([\.idempotencyKey])

        public var idempotencyKey: String
        public var principalId: String
        public var kindRaw: String
        public var requestBodyData: Data
        public var referenceNumber: String?
        public var statusRaw: String
        public var createdAt: Date
        public var updatedAt: Date

        public init(
            idempotencyKey: String,
            principalId: String,
            kindRaw: String,
            requestBodyData: Data,
            referenceNumber: String?,
            statusRaw: String,
            createdAt: Date,
            updatedAt: Date,
        ) {
            self.idempotencyKey = idempotencyKey
            self.principalId = principalId
            self.kindRaw = kindRaw
            self.requestBodyData = requestBodyData
            self.referenceNumber = referenceNumber
            self.statusRaw = statusRaw
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}
