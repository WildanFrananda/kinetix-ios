import Foundation

public struct SearchCategoryFacet: Equatable, Hashable, Codable, Sendable {
    public let categorySlug: CategorySlug
    public let count: Int

    public init(
        categorySlug: CategorySlug,
        count: Int,
    ) {
        self.categorySlug = categorySlug
        self.count = count
    }
}
