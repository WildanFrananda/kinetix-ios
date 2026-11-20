import Foundation
import SwiftData

extension CacheSchemaV1 {
    @Model
    public final class CachedCatalogPayloadRecord {
        #Unique<CachedCatalogPayloadRecord>([\.cacheKey])

        public var cacheKey: String
        public var payloadData: Data
        public var updatedAt: Date

        public init(
            cacheKey: String,
            payloadData: Data,
            updatedAt: Date,
        ) {
            self.cacheKey = cacheKey
            self.payloadData = payloadData
            self.updatedAt = updatedAt
        }
    }
}
