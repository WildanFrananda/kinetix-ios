import Foundation

public enum DiscountType: String, Equatable, Hashable, Codable, Sendable {
    case percentage = "PERCENTAGE"
    case fixed = "FIXED"
    case unknown = "UNKNOWN"

    public init(wireValue: String) {
        switch wireValue.uppercased() {
        case "PERCENTAGE":
            self = .percentage
        case "FIXED":
            self = .fixed
        default:
            self = .unknown
        }
    }
}
