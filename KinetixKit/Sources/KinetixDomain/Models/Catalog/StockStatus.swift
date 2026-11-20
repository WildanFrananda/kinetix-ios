import Foundation

public enum StockStatus: String, Equatable, Hashable, Codable, Sendable {
    case inStock = "in_stock"
    case outOfStock = "out_of_stock"
    case unknown = "unknown"

    public init(wireValue: String) {
        switch wireValue {
        case "in_stock":
            self = .inStock
        case "out_of_stock":
            self = .outOfStock
        default:
            self = .unknown
        }
    }
}
