import Foundation
import KinetixDomain

public struct FlashSaleResponseDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let productId: String
    public let flashPrice: String
    public let stockLimit: Int
    public let stockSold: Int
    public let active: Bool
    public let startTime: String
    public let endTime: String
    public let createdAt: String?
    public let updatedAt: String?
    public let merchantPrincipalId: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case productId = "product_id"
        case flashPrice = "flash_price"
        case stockLimit = "stock_limit"
        case stockSold = "stock_sold"
        case active = "active"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case merchantPrincipalId = "merchant_principal_id"
    }

    public func toDomain() -> FlashSale? {
        guard let validSku = ProductSku(productId),
            let parsedPrice = WireDecimal.parse(flashPrice),
            let parsedStart = WireTimestamp.parseRFC3339(startTime),
            let parsedEnd = WireTimestamp.parseRFC3339(endTime)
        else {
            return nil
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

        return FlashSale(
            id: id,
            title: title,
            productSku: validSku,
            flashPrice: parsedPrice,
            stockLimit: stockLimit,
            stockSold: stockSold,
            active: active,
            startTime: parsedStart,
            endTime: parsedEnd,
            merchantPrincipalId: merchantId,
        )
    }
}
