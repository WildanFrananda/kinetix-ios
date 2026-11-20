import Foundation

public struct PriceIndication: Equatable, Hashable, Codable, Sendable {
    public let basePrice: Decimal
    public let finalUnitPrice: Decimal
    public let savingsPerUnit: Decimal
    public let currency: String
    public let appliedPromotion: AppliedPromotionKind

    public init(
        basePrice: Decimal,
        finalUnitPrice: Decimal,
        savingsPerUnit: Decimal,
        currency: String,
        appliedPromotion: AppliedPromotionKind,
    ) {
        self.basePrice = basePrice
        self.finalUnitPrice = finalUnitPrice
        self.savingsPerUnit = savingsPerUnit
        self.currency = currency
        self.appliedPromotion = appliedPromotion
    }

    public var hasSavings: Bool {
        return savingsPerUnit > 0 && finalUnitPrice < basePrice
    }
}
