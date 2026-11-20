import Foundation
import KinetixDomain

public struct ReviewItemDTO: Codable, Sendable {
    public let id: String
    public let productId: String
    public let rating: Int
    public let comment: String?
    public let createdAt: String
    public let updatedAt: String
    public let merchantPrincipalId: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case productId = "product_id"
        case rating = "rating"
        case comment = "comment"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case merchantPrincipalId = "merchant_principal_id"
    }

    public func toDomain() -> ProductReview? {
        guard let validId = ReviewId(id),
            let validSku = ProductSku(productId),
            let validMerchant = PrincipalId(merchantPrincipalId),
            let parsedCreated = WireTimestamp.parseRFC3339(createdAt),
            let parsedUpdated = WireTimestamp.parseRFC3339(updatedAt)
        else {
            return nil
        }

        return ProductReview(
            id: validId,
            productSku: validSku,
            merchantPrincipalId: validMerchant,
            rating: rating,
            comment: comment,
            createdAt: parsedCreated,
            updatedAt: parsedUpdated,
        )
    }
}
