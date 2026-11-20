import Foundation

public struct ReviewPage: Equatable, Hashable, Codable, Sendable {
    public let averageRating: Decimal
    public let totalReviews: Int
    public let items: [ProductReview]
    public let currentPage: Int
    public let lastPage: Int

    public init(
        averageRating: Decimal,
        totalReviews: Int,
        items: [ProductReview],
        currentPage: Int,
        lastPage: Int,
    ) {
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.items = items
        self.currentPage = currentPage
        self.lastPage = lastPage
    }

    public var hasNextPage: Bool {
        return currentPage < lastPage
    }
}
