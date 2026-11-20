import Foundation

public struct SearchQuery: Equatable, Hashable, Codable, Sendable {
    public let queryText: String?
    public let categorySlugs: [CategorySlug]
    public let sort: SearchSortOption?
    public let limit: Int
    public let offset: Int

    public init(
        queryText: String? = nil,
        categorySlugs: [CategorySlug] = [],
        sort: SearchSortOption? = nil,
        limit: Int = 20,
        offset: Int = 0,
    ) {
        let trimmed = queryText?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.queryText = (trimmed?.isEmpty == false) ? trimmed : nil
        self.categorySlugs = categorySlugs
        self.sort = sort
        self.limit = min(max(1, limit), 100)
        self.offset = max(0, offset)
    }
}
