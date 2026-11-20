import Foundation
import KinetixDomain
import SwiftData

@ModelActor
public actor CacheStoreActor {
    public func isExecutingOffMainThread() -> Bool {
        return !Thread.isMainThread
    }

    public func readProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) throws -> DeliveryProfile? {
        let targetAccount = accountId.value
        let targetPrincipal = principalId.value
        let descriptor = FetchDescriptor<CachedProfileRecord>(
            predicate: #Predicate<CachedProfileRecord> { record in
                record.accountId == targetAccount && record.principalId == targetPrincipal
            }
        )

        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }

        guard let validAccountId = AccountId(record.accountId) else {
            return nil
        }

        return DeliveryProfile(
            id: record.profileId,
            accountId: validAccountId,
            fullName: record.fullName,
            phoneNumber: record.phoneNumber,
            streetAddress: record.streetAddress,
            city: record.city,
            postalCode: record.postalCode,
            avatarURL: record.avatarURL,
            latitude: record.latitude,
            longitude: record.longitude,
            geocodedAt: record.geocodedAt,
        )
    }

    public func saveProfile(
        _ profile: DeliveryProfile,
        principalId: PrincipalId,
        savedAt: Date,
    ) throws {
        let targetAccount = profile.accountId.value
        let descriptor = FetchDescriptor<CachedProfileRecord>(
            predicate: #Predicate<CachedProfileRecord> { record in
                record.accountId == targetAccount
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.principalId = principalId.value
            existing.profileId = profile.id
            existing.fullName = profile.fullName
            existing.phoneNumber = profile.phoneNumber
            existing.streetAddress = profile.streetAddress
            existing.city = profile.city
            existing.postalCode = profile.postalCode
            existing.avatarURL = profile.avatarURL
            existing.latitude = profile.latitude
            existing.longitude = profile.longitude
            existing.geocodedAt = profile.geocodedAt
            existing.updatedAt = savedAt
        } else {
            let record = CachedProfileRecord(
                accountId: profile.accountId.value,
                principalId: principalId.value,
                profileId: profile.id,
                fullName: profile.fullName,
                phoneNumber: profile.phoneNumber,
                streetAddress: profile.streetAddress,
                city: profile.city,
                postalCode: profile.postalCode,
                avatarURL: profile.avatarURL,
                latitude: profile.latitude,
                longitude: profile.longitude,
                geocodedAt: profile.geocodedAt,
                updatedAt: savedAt,
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    public func clearProfile(for principalId: PrincipalId) throws {
        let targetPrincipal = principalId.value
        let descriptor = FetchDescriptor<CachedProfileRecord>(
            predicate: #Predicate<CachedProfileRecord> { record in
                record.principalId == targetPrincipal
            }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    public func readCatalogPayload(forKey key: String) throws -> Data? {
        let targetKey = key
        let descriptor = FetchDescriptor<CachedCatalogPayloadRecord>(
            predicate: #Predicate<CachedCatalogPayloadRecord> { record in
                record.cacheKey == targetKey
            }
        )

        return try modelContext.fetch(descriptor).first?.payloadData
    }

    public func saveCatalogPayload(
        _ data: Data,
        forKey key: String,
        savedAt: Date,
    ) throws {
        let targetKey = key
        let descriptor = FetchDescriptor<CachedCatalogPayloadRecord>(
            predicate: #Predicate<CachedCatalogPayloadRecord> { record in
                record.cacheKey == targetKey
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payloadData = data
            existing.updatedAt = savedAt
        } else {
            let record = CachedCatalogPayloadRecord(
                cacheKey: key,
                payloadData: data,
                updatedAt: savedAt,
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }
}
