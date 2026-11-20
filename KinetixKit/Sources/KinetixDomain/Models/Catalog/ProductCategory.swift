import Foundation

public struct ProductCategory: Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let name: String
    public let slug: CategorySlug

    public init(
        id: Int,
        name: String,
        slug: CategorySlug,
    ) {
        self.id = id
        self.name = name
        self.slug = slug
    }
}
