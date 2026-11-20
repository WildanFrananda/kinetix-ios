import Foundation
import KinetixDomain

public struct DiscountResponseDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let discountType: String
    public let value: String
    public let targetProductId: String?
    public let targetCategoryId: String?
    public let active: Bool
    public let startTime: String
    public let endTime: String
    public let createdAt: String?
    public let updatedAt: String?
    public let merchantPrincipalId: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case discountType = "discount_type"
        case value = "value"
        case targetProductId = "target_product_id"
        case targetCategoryId = "target_category_id"
        case active = "active"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case merchantPrincipalId = "merchant_principal_id"
    }

    public func toDomain() -> PromotionDiscount? {
        guard let parsedValue = WireDecimal.parse(value),
            let parsedStart = WireTimestamp.parseRFC3339(startTime),
            let parsedEnd = WireTimestamp.parseRFC3339(endTime)
        else {
            return nil
        }

        let targetSku: ProductSku?
        if let rawProduct = targetProductId,
            !rawProduct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            guard let validSku = ProductSku(rawProduct) else {
                return nil
            }

            targetSku = validSku
        } else {
            targetSku = nil
        }

        let targetCategory: CategorySlug?
        if let rawCategory = targetCategoryId,
            !rawCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            guard let validCategory = CategorySlug(rawCategory) else {
                return nil
            }

            targetCategory = validCategory
        } else {
            targetCategory = nil
        }

        let merchantId: PrincipalId?
        if let rawMerchant = merchantPrincipalId,
            !rawMerchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            guard let validMerchant = PrincipalId(rawMerchant) else {
                return nil
            }

            merchantId = validMerchant
        } else {
            merchantId = nil
        }

        return PromotionDiscount(
            id: id,
            title: title,
            discountType: DiscountType(wireValue: discountType),
            value: parsedValue,
            targetProductSku: targetSku,
            targetCategorySlug: targetCategory,
            active: active,
            startTime: parsedStart,
            endTime: parsedEnd,
            merchantPrincipalId: merchantId,
        )
    }
}
