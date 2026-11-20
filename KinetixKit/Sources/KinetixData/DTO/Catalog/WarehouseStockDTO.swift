import Foundation
import KinetixDomain

public struct WarehouseStockDTO: Codable, Sendable {
    public let sku: String
    public let binLocation: String?
    public let availableQuantity: Int?
    public let reservedQuantity: Int?
    public let stockStatus: String

    enum CodingKeys: String, CodingKey {
        case sku = "sku"
        case binLocation = "bin_location"
        case availableQuantity = "available_quantity"
        case reservedQuantity = "reserved_quantity"
        case stockStatus = "stock_status"
    }

    public func toDomain() -> WarehouseStock? {
        guard let validSku = ProductSku(sku) else {
            return nil
        }

        return WarehouseStock(
            sku: validSku,
            binLocation: binLocation,
            availableQuantity: availableQuantity,
            reservedQuantity: reservedQuantity,
            stockStatus: StockStatus(wireValue: stockStatus),
        )
    }
}
