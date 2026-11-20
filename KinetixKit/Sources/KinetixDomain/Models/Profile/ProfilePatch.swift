import Foundation

public struct ProfilePatch: Sendable, Equatable, Codable {
    public let fullName: String?
    public let phoneNumber: String?
    public let streetAddress: String?
    public let city: String?
    public let postalCode: String?
    public let avatarUpdate: AvatarUpdate

    public init(
        fullName: String? = nil,
        phoneNumber: String? = nil,
        streetAddress: String? = nil,
        city: String? = nil,
        postalCode: String? = nil,
        avatarUpdate: AvatarUpdate = .unchanged,
    ) {
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.streetAddress = streetAddress
        self.city = city
        self.postalCode = postalCode
        self.avatarUpdate = avatarUpdate
    }

    public var isEmpty: Bool {
        fullName == nil
            && phoneNumber == nil
            && streetAddress == nil
            && city == nil
            && postalCode == nil
            && avatarUpdate == .unchanged
    }

    public func merged(with newer: ProfilePatch) -> ProfilePatch {
        let mergedAvatar: AvatarUpdate
        switch newer.avatarUpdate {
        case .unchanged:
            mergedAvatar = avatarUpdate
        case .set, .remove:
            mergedAvatar = newer.avatarUpdate
        }

        return ProfilePatch(
            fullName: newer.fullName ?? fullName,
            phoneNumber: newer.phoneNumber ?? phoneNumber,
            streetAddress: newer.streetAddress ?? streetAddress,
            city: newer.city ?? city,
            postalCode: newer.postalCode ?? postalCode,
            avatarUpdate: mergedAvatar,
        )
    }

    public func applied(
        to base: DeliveryProfile?,
        accountId: AccountId,
    ) -> DeliveryProfile {
        let resolvedAvatar: String?
        switch avatarUpdate {
        case .unchanged:
            resolvedAvatar = base?.avatarURL
        case .set(let url):
            resolvedAvatar = url
        case .remove:
            resolvedAvatar = nil
        }

        return DeliveryProfile(
            id: base?.id ?? 0,
            accountId: accountId,
            fullName: fullName ?? base?.fullName ?? "",
            phoneNumber: phoneNumber ?? base?.phoneNumber ?? "",
            streetAddress: streetAddress ?? base?.streetAddress ?? "",
            city: city ?? base?.city ?? "",
            postalCode: postalCode ?? base?.postalCode ?? "",
            avatarURL: resolvedAvatar,
            latitude: base?.latitude,
            longitude: base?.longitude,
            geocodedAt: base?.geocodedAt,
        )
    }

    public static func diff(
        from confirmed: DeliveryProfile?,
        to draft: ProfileDraft,
    ) -> ProfilePatch {
        let trimmedFullName = draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = draft.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStreet = draft.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = draft.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPostal = draft.postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAvatar = draft.avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let nextFullName: String? =
            (confirmed == nil && !trimmedFullName.isEmpty)
                || (confirmed != nil && trimmedFullName != confirmed?.fullName)
            ? trimmedFullName : nil

        let nextPhone: String? =
            (confirmed == nil && !trimmedPhone.isEmpty)
                || (confirmed != nil && trimmedPhone != confirmed?.phoneNumber)
            ? trimmedPhone : nil

        let nextStreet: String? =
            (confirmed == nil && !trimmedStreet.isEmpty)
                || (confirmed != nil && trimmedStreet != confirmed?.streetAddress)
            ? trimmedStreet : nil

        let nextCity: String? =
            (confirmed == nil && !trimmedCity.isEmpty)
                || (confirmed != nil && trimmedCity != confirmed?.city)
            ? trimmedCity : nil

        let nextPostal: String? =
            (confirmed == nil && !trimmedPostal.isEmpty)
                || (confirmed != nil && trimmedPostal != confirmed?.postalCode)
            ? trimmedPostal : nil

        let avatarUpdate: AvatarUpdate
        if trimmedAvatar.isEmpty {
            if confirmed?.avatarURL != nil {
                avatarUpdate = .remove
            } else {
                avatarUpdate = .unchanged
            }
        } else if trimmedAvatar != confirmed?.avatarURL {
            avatarUpdate = .set(trimmedAvatar)
        } else {
            avatarUpdate = .unchanged
        }

        return ProfilePatch(
            fullName: nextFullName,
            phoneNumber: nextPhone,
            streetAddress: nextStreet,
            city: nextCity,
            postalCode: nextPostal,
            avatarUpdate: avatarUpdate,
        )
    }
}
