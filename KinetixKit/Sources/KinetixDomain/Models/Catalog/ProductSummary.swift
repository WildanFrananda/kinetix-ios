import Foundation

public struct ProductSummary: Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let sku: ProductSku
    public let title: String
    public let categoryName: String
    public let categorySlug: CategorySlug
    public let price: Decimal
    public let currency: String
    public let imageURL: URL?
    public let merchantPrincipalId: PrincipalId
    public let weightGrams: Int?
    public let availableStock: Int?
    public let isInStock: Bool?
    public let stockStatus: StockStatus

    public init(
        id: Int,
        sku: ProductSku,
        title: String,
        categoryName: String,
        categorySlug: CategorySlug,
        price: Decimal,
        currency: String,
        imageURL: URL?,
        merchantPrincipalId: PrincipalId,
        weightGrams: Int?,
        availableStock: Int?,
        isInStock: Bool?,
        stockStatus: StockStatus,
    ) {
        self.id = id
        self.sku = sku
        self.title = title
        self.categoryName = categoryName
        self.categorySlug = categorySlug
        self.price = price
        self.currency = currency
        self.imageURL = imageURL
        self.merchantPrincipalId = merchantPrincipalId
        self.weightGrams = weightGrams
        self.availableStock = availableStock
        self.isInStock = isInStock
        self.stockStatus = stockStatus
    }
}
