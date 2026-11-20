import Foundation

public struct ProductReview: Equatable, Hashable, Codable, Sendable {
    public let id: ReviewId
    public let productSku: ProductSku
    public let merchantPrincipalId: PrincipalId
    public let rating: Int
    public let comment: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: ReviewId,
        productSku: ProductSku,
        merchantPrincipalId: PrincipalId,
        rating: Int,
        comment: String?,
        createdAt: Date,
        updatedAt: Date,
    ) {
        self.id = id
        self.productSku = productSku
        self.merchantPrincipalId = merchantPrincipalId
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
