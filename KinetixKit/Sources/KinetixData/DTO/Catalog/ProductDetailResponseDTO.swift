import Foundation
import KinetixDomain

public struct ProductDetailResponseDTO: Codable, Sendable {
    public let id: Int
    public let sku: String
    public let title: String
    public let descriptionText: String
    public let category: String
    public let categorySlug: String
    public let price: String
    public let currency: String
    public let imageURL: String?
    public let merchantPrincipalId: String
    public let weightGrams: Int?
    public let warehouseStock: WarehouseStockDTO

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case sku = "sku"
        case title = "title"
        case descriptionText = "description"
        case category = "category"
        case categorySlug = "category_slug"
        case price = "price"
        case currency = "currency"
        case imageURL = "image_url"
        case merchantPrincipalId = "merchant_principal_id"
        case weightGrams = "weight_grams"
        case warehouseStock = "warehouse_stock"
    }

    public func toDomain() -> ProductDetail? {
        guard let validSku = ProductSku(sku),
            let validCategorySlug = CategorySlug(categorySlug),
            let validMerchantId = PrincipalId(merchantPrincipalId),
            let parsedPrice = WireDecimal.parse(price),
            let mappedStock = warehouseStock.toDomain()
        else {
            return nil
        }

        return ProductDetail(
            id: id,
            sku: validSku,
            title: title,
            descriptionText: descriptionText,
            categoryName: category,
            categorySlug: validCategorySlug,
            price: parsedPrice,
            currency: currency,
            imageURL: WireDecimal.parseHTTPSURL(imageURL),
            merchantPrincipalId: validMerchantId,
            weightGrams: weightGrams,
            warehouseStock: mappedStock,
        )
    }
}
