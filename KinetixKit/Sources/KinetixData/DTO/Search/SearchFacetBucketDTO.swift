import Foundation
import KinetixDomain

public struct SearchFacetBucketDTO: Codable, Sendable {
    public let value: String
    public let count: Int

    enum CodingKeys: String, CodingKey {
        case value = "value"
        case count = "count"
    }

    public func toCategoryFacet() -> SearchCategoryFacet? {
        guard let slug = CategorySlug(value) else {
            return nil
        }

        return SearchCategoryFacet(
            categorySlug: slug,
            count: count,
        )
    }
}
