import Foundation

public struct PromotionDiscount: Equatable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let discountType: DiscountType
    public let value: Decimal
    public let targetProductSku: ProductSku?
    public let targetCategorySlug: CategorySlug?
    public let active: Bool
    public let startTime: Date
    public let endTime: Date
    public let merchantPrincipalId: PrincipalId?

    public init(
        id: String,
        title: String,
        discountType: DiscountType,
        value: Decimal,
        targetProductSku: ProductSku?,
        targetCategorySlug: CategorySlug?,
        active: Bool,
        startTime: Date,
        endTime: Date,
        merchantPrincipalId: PrincipalId?,
    ) {
        self.id = id
        self.title = title
        self.discountType = discountType
        self.value = value
        self.targetProductSku = targetProductSku
        self.targetCategorySlug = targetCategorySlug
        self.active = active
        self.startTime = startTime
        self.endTime = endTime
        self.merchantPrincipalId = merchantPrincipalId
    }
}
