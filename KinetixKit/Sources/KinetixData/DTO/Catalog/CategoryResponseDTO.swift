import Foundation
import KinetixDomain

public struct CategoryResponseDTO: Codable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case slug = "slug"
    }

    public func toDomain() -> ProductCategory? {
        guard let validSlug = CategorySlug(slug),
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return ProductCategory(
            id: id,
            name: name,
            slug: validSlug,
        )
    }
}
