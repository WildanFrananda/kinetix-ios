import Foundation
import KinetixDomain

public struct ProfileResponseDTO: Decodable, Sendable, Equatable {
    public let id: Int
    public let userId: Int
    public let fullName: String
    public let phoneNumber: String
    public let streetAddress: String
    public let city: String
    public let postalCode: String
    public let avatarUrl: String?
    public let latitude: Double?
    public let longitude: Double?
    public let geocodedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case fullName
        case phoneNumber
        case streetAddress
        case city
        case postalCode
        case avatarUrl
        case latitude
        case longitude
        case geocodedAt
    }

    public func toDomain() -> DeliveryProfile? {
        guard let accountId = AccountId(userId) else {
            return nil
        }

        let parsedGeocodedAt: Date?
        if let geocodedAt {
            parsedGeocodedAt = WireTimestamp.parseRFC3339(geocodedAt)
        } else {
            parsedGeocodedAt = nil
        }

        let sanitizedAvatar: String?
        if let avatarUrl,
            let components = URLComponents(string: avatarUrl),
            components.scheme?.lowercased() == "https",
            let host = components.host,
            !host.isEmpty
        {
            sanitizedAvatar = avatarUrl
        } else {
            sanitizedAvatar = nil
        }

        return DeliveryProfile(
            id: id,
            accountId: accountId,
            fullName: fullName,
            phoneNumber: phoneNumber,
            streetAddress: streetAddress,
            city: city,
            postalCode: postalCode,
            avatarURL: sanitizedAvatar,
            latitude: latitude,
            longitude: longitude,
            geocodedAt: parsedGeocodedAt,
        )
    }
}
