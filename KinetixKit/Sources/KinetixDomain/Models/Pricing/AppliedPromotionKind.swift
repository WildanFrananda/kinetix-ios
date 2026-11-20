import Foundation

public enum AppliedPromotionKind: Equatable, Hashable, Codable, Sendable {
    case none
    case flashSale(title: String)
    case discount(title: String)
}
