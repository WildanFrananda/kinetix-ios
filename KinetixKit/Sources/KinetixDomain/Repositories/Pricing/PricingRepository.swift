import Foundation

public protocol PricingRepository: Sendable {
    func listDiscounts() async -> Result<[PromotionDiscount], Failure>

    func getFlashSale(
        productSku: ProductSku
    ) async -> Result<FlashSale?, Failure>
}
