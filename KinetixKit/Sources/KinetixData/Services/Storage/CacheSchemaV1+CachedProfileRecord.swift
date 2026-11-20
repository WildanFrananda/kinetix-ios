import Foundation
import SwiftData

extension CacheSchemaV1 {
    @Model
    public final class CachedProfileRecord {
        #Unique<CachedProfileRecord>([\.accountId])

        public var accountId: Int
        public var principalId: String
        public var profileId: Int
        public var fullName: String
        public var phoneNumber: String
        public var streetAddress: String
        public var city: String
        public var postalCode: String
        public var avatarURL: String?
        public var latitude: Double?
        public var longitude: Double?
        public var geocodedAt: Date?
        public var updatedAt: Date

        public init(
            accountId: Int,
            principalId: String,
            profileId: Int,
            fullName: String,
            phoneNumber: String,
            streetAddress: String,
            city: String,
            postalCode: String,
            avatarURL: String?,
            latitude: Double?,
            longitude: Double?,
            geocodedAt: Date?,
            updatedAt: Date,
        ) {
            self.accountId = accountId
            self.principalId = principalId
            self.profileId = profileId
            self.fullName = fullName
            self.phoneNumber = phoneNumber
            self.streetAddress = streetAddress
            self.city = city
            self.postalCode = postalCode
            self.avatarURL = avatarURL
            self.latitude = latitude
            self.longitude = longitude
            self.geocodedAt = geocodedAt
            self.updatedAt = updatedAt
        }
    }
}
