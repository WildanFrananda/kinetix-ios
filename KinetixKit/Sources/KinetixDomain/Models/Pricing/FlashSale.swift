import Foundation

public struct FlashSale: Equatable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let productSku: ProductSku
    public let flashPrice: Decimal
    public let stockLimit: Int
    public let stockSold: Int
    public let active: Bool
    public let startTime: Date
    public let endTime: Date
    public let merchantPrincipalId: PrincipalId?

    public init(
        id: String,
        title: String,
        productSku: ProductSku,
        flashPrice: Decimal,
        stockLimit: Int,
        stockSold: Int,
        active: Bool,
        startTime: Date,
        endTime: Date,
        merchantPrincipalId: PrincipalId?,
    ) {
        self.id = id
        self.title = title
        self.productSku = productSku
        self.flashPrice = flashPrice
        self.stockLimit = stockLimit
        self.stockSold = stockSold
        self.active = active
        self.startTime = startTime
        self.endTime = endTime
        self.merchantPrincipalId = merchantPrincipalId
    }

    public var remainingStock: Int {
        return max(0, stockLimit - stockSold)
    }
}
