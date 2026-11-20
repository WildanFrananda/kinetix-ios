import Foundation
import KinetixDomain

public struct ProductReviewsResponseDTO: Codable, Sendable {
    public let productId: String
    public let averageRating: Decimal
    public let totalReviews: Int
    public let data: [ReviewItemDTO]
    public let currentPage: Int
    public let lastPage: Int

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
        case data = "data"
        case currentPage = "current_page"
        case lastPage = "last_page"
    }

    public func toDomain() -> ReviewPage? {
        var items: [ProductReview] = []
        items.reserveCapacity(data.count)

        for dto in data {
            guard let item = dto.toDomain() else {
                return nil
            }

            items.append(item)
        }

        return ReviewPage(
            averageRating: averageRating,
            totalReviews: totalReviews,
            items: items,
            currentPage: currentPage,
            lastPage: lastPage,
        )
    }
}
