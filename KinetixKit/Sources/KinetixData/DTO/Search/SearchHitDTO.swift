import Foundation
import KinetixDomain

public struct SearchHitDTO: Codable, Sendable {
    public let id: String
    public let merchantId: String
    public let title: String
    public let descriptionText: String?
    public let categories: [String]?
    public let priceMinor: Int64
    public let currency: String
    public let updatedAtMillis: Int64

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case merchantId = "merchant_id"
        case title = "title"
        case descriptionText = "description"
        case categories = "categories"
        case priceMinor = "price_minor"
        case currency = "currency"
        case updatedAtMillis = "updated_at_ms"
    }

    public func toDomain() -> SearchHit? {
        guard let validSku = ProductSku(id),
            let validMerchantId = PrincipalId(merchantId)
        else {
            return nil
        }

        var mappedCategories: [CategorySlug] = []
        if let categories {
            for rawCategory in categories {
                if let slug = CategorySlug(rawCategory) {
                    mappedCategories.append(slug)
                }
            }
        }

        return SearchHit(
            sku: validSku,
            merchantPrincipalId: validMerchantId,
            title: title,
            descriptionText: descriptionText,
            categorySlugs: mappedCategories,
            priceMinor: priceMinor,
            currency: currency,
            updatedAtMillis: updatedAtMillis,
        )
    }
}
