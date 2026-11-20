import Foundation

public struct ProductPage: Equatable, Hashable, Codable, Sendable {
    public let totalCount: Int
    public let page: Int
    public let pageSize: Int
    public let items: [ProductSummary]

    public init(
        totalCount: Int,
        page: Int,
        pageSize: Int,
        items: [ProductSummary],
    ) {
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
        self.items = items
    }

    public var hasNextPage: Bool {
        return page * pageSize < totalCount
    }
}
