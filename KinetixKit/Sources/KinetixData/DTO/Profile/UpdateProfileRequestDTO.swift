import Foundation
import KinetixDomain

public struct UpdateProfileRequestDTO: Encodable, Sendable, Equatable {
    public let patch: ProfilePatch

    public init(patch: ProfilePatch) {
        self.patch = patch
    }

    enum CodingKeys: String, CodingKey {
        case fullName
        case phoneNumber
        case streetAddress
        case city
        case postalCode
        case avatarUrl
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let fullName = patch.fullName {
            try container.encode(fullName, forKey: .fullName)
        }

        if let phoneNumber = patch.phoneNumber {
            try container.encode(phoneNumber, forKey: .phoneNumber)
        }

        if let streetAddress = patch.streetAddress {
            try container.encode(streetAddress, forKey: .streetAddress)
        }

        if let city = patch.city {
            try container.encode(city, forKey: .city)
        }

        if let postalCode = patch.postalCode {
            try container.encode(postalCode, forKey: .postalCode)
        }

        switch patch.avatarUpdate {
        case .unchanged:
            break
        case .set(let url):
            try container.encode(url, forKey: .avatarUrl)
        case .remove:
            try container.encodeNil(forKey: .avatarUrl)
        }
    }
}
