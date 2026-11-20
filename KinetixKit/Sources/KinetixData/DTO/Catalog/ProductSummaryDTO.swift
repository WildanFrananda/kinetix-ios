import Foundation
import KinetixDomain

public struct ProductSummaryDTO: Codable, Sendable {
    public let id: Int
    public let sku: String
    public let title: String
    public let category: String
    public let categorySlug: String
    public let price: String
    public let currency: String
    public let imageURL: String?
    public let merchantPrincipalId: String
    public let weightGrams: Int?
    public let availableStock: Int?
    public let isInStock: Bool?
    public let stockStatus: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case sku = "sku"
        case title = "title"
        case category = "category"
        case categorySlug = "category_slug"
        case price = "price"
        case currency = "currency"
        case imageURL = "image_url"
        case merchantPrincipalId = "merchant_principal_id"
        case weightGrams = "weight_grams"
        case availableStock = "available_stock"
        case isInStock = "is_in_stock"
        case stockStatus = "stock_status"
    }

    public func toDomain() -> ProductSummary? {
        guard let validSku = ProductSku(sku),
            let validCategorySlug = CategorySlug(categorySlug),
            let validMerchantId = PrincipalId(merchantPrincipalId),
            let parsedPrice = WireDecimal.parse(price)
        else {
            return nil
        }

        return ProductSummary(
            id: id,
            sku: validSku,
            title: title,
            categoryName: category,
            categorySlug: validCategorySlug,
            price: parsedPrice,
            currency: currency,
            imageURL: WireDecimal.parseHTTPSURL(imageURL),
            merchantPrincipalId: validMerchantId,
            weightGrams: weightGrams,
            availableStock: availableStock,
            isInStock: isInStock,
            stockStatus: StockStatus(wireValue: stockStatus),
        )
    }
}
