import Foundation

public struct SearchFacetsDTO: Codable, Sendable {
    public let categories: [SearchFacetBucketDTO]?

    enum CodingKeys: String, CodingKey {
        case categories = "categories"
    }
}
