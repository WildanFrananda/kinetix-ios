import Foundation

public struct ProductListQuery: Equatable, Hashable, Codable, Sendable {
    public let categorySlug: CategorySlug?
    public let searchText: String?
    public let page: Int
    public let pageSize: Int

    public init(
        categorySlug: CategorySlug? = nil,
        searchText: String? = nil,
        page: Int = 1,
        pageSize: Int = 20,
    ) {
        self.categorySlug = categorySlug
        let trimmed = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText = (trimmed?.isEmpty == false) ? trimmed : nil
        self.page = max(1, page)
        self.pageSize = min(max(1, pageSize), 100)
    }

    public var cacheKey: String {
        let cat = categorySlug?.value ?? "*"
        let q = searchText ?? "*"
        return "category=\(cat)|q=\(q)|page=\(page)|size=\(pageSize)"
    }
}
