import Foundation

public struct WarehouseStock: Equatable, Hashable, Codable, Sendable {
    public let sku: ProductSku
    public let binLocation: String?
    public let availableQuantity: Int?
    public let reservedQuantity: Int?
    public let stockStatus: StockStatus

    public init(
        sku: ProductSku,
        binLocation: String?,
        availableQuantity: Int?,
        reservedQuantity: Int?,
        stockStatus: StockStatus,
    ) {
        self.sku = sku
        self.binLocation = binLocation
        self.availableQuantity = availableQuantity
        self.reservedQuantity = reservedQuantity
        self.stockStatus = stockStatus
    }
}
