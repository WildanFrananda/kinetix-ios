import Foundation

public enum UserRole: Sendable, Equatable, Hashable, Codable {
    case customer
    case merchant
    case courier
    case admin
    case unknown(String)

    public init(rawWireValue: String) {
        switch rawWireValue.lowercased() {
        case "customer":
            self = .customer
        case "merchant":
            self = .merchant
        case "courier":
            self = .courier
        case "admin":
            self = .admin
        default:
            self = .unknown(rawWireValue)
        }
    }

    public var isBuyerAccount: Bool {
        self == .customer
    }
}
