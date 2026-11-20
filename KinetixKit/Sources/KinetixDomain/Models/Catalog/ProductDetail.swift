import Foundation

public struct ProductDetail: Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let sku: ProductSku
    public let title: String
    public let descriptionText: String
    public let categoryName: String
    public let categorySlug: CategorySlug
    public let price: Decimal
    public let currency: String
    public let imageURL: URL?
    public let merchantPrincipalId: PrincipalId
    public let weightGrams: Int?
    public let warehouseStock: WarehouseStock

    public init(
        id: Int,
        sku: ProductSku,
        title: String,
        descriptionText: String,
        categoryName: String,
        categorySlug: CategorySlug,
        price: Decimal,
        currency: String,
        imageURL: URL?,
        merchantPrincipalId: PrincipalId,
        weightGrams: Int?,
        warehouseStock: WarehouseStock,
    ) {
        self.id = id
        self.sku = sku
        self.title = title
        self.descriptionText = descriptionText
        self.categoryName = categoryName
        self.categorySlug = categorySlug
        self.price = price
        self.currency = currency
        self.imageURL = imageURL
        self.merchantPrincipalId = merchantPrincipalId
        self.weightGrams = weightGrams
        self.warehouseStock = warehouseStock
    }
}
