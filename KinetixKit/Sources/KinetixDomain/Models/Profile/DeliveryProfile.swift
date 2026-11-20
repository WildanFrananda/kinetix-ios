import Foundation

public struct DeliveryProfile: Sendable, Equatable, Codable {
    public let id: Int
    public let accountId: AccountId
    public let fullName: String
    public let phoneNumber: String
    public let streetAddress: String
    public let city: String
    public let postalCode: String
    public let avatarURL: String?
    public let latitude: Double?
    public let longitude: Double?
    public let geocodedAt: Date?

    public init(
        id: Int,
        accountId: AccountId,
        fullName: String,
        phoneNumber: String,
        streetAddress: String,
        city: String,
        postalCode: String,
        avatarURL: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        geocodedAt: Date? = nil,
    ) {
        self.id = id
        self.accountId = accountId
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.streetAddress = streetAddress
        self.city = city
        self.postalCode = postalCode
        self.avatarURL = avatarURL
        self.latitude = latitude
        self.longitude = longitude
        self.geocodedAt = geocodedAt
    }
}
