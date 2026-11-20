import Foundation

public struct ProfileDraft: Sendable, Equatable {
    public var fullName: String
    public var phoneNumber: String
    public var streetAddress: String
    public var city: String
    public var postalCode: String
    public var avatarURL: String

    public init(
        fullName: String = "",
        phoneNumber: String = "",
        streetAddress: String = "",
        city: String = "",
        postalCode: String = "",
        avatarURL: String = "",
    ) {
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.streetAddress = streetAddress
        self.city = city
        self.postalCode = postalCode
        self.avatarURL = avatarURL
    }

    public init(profile: DeliveryProfile) {
        self.fullName = profile.fullName
        self.phoneNumber = profile.phoneNumber
        self.streetAddress = profile.streetAddress
        self.city = profile.city
        self.postalCode = profile.postalCode
        self.avatarURL = profile.avatarURL ?? ""
    }
}
