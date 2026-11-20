import Foundation

public struct SearchHit: Equatable, Hashable, Codable, Sendable {
    public let sku: ProductSku
    public let merchantPrincipalId: PrincipalId
    public let title: String
    public let descriptionText: String?
    public let categorySlugs: [CategorySlug]
    public let priceMinor: Int64
    public let currency: String
    public let updatedAtMillis: Int64

    public init(
        sku: ProductSku,
        merchantPrincipalId: PrincipalId,
        title: String,
        descriptionText: String?,
        categorySlugs: [CategorySlug],
        priceMinor: Int64,
        currency: String,
        updatedAtMillis: Int64,
    ) {
        self.sku = sku
        self.merchantPrincipalId = merchantPrincipalId
        self.title = title
        self.descriptionText = descriptionText
        self.categorySlugs = categorySlugs
        self.priceMinor = priceMinor
        self.currency = currency
        self.updatedAtMillis = updatedAtMillis
    }

    public var indicativePriceMajor: Decimal {
        return Decimal(priceMinor) / Decimal(100)
    }
}
