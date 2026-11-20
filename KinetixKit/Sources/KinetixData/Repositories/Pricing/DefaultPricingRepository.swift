import Foundation
import KinetixDomain

public struct DefaultPricingRepository: PricingRepository {
    private let apiClient: PricingAPIClient
    private let discountsCoalescer = InFlightReadCoalescer<
        String,
        Result<[PromotionDiscount], Failure>
    >()
    private let flashSaleCoalescer = InFlightReadCoalescer<
        ProductSku,
        Result<FlashSale?, Failure>
    >()

    public init(apiClient: PricingAPIClient) {
        self.apiClient = apiClient
    }

    public func listDiscounts() async -> Result<[PromotionDiscount], Failure> {
        let apiClient = self.apiClient
        return await discountsCoalescer.coalesce(key: "discounts") {
            return await apiClient.listDiscounts()
        }
    }

    public func getFlashSale(productSku: ProductSku) async -> Result<FlashSale?, Failure> {
        let apiClient = self.apiClient
        return await flashSaleCoalescer.coalesce(key: productSku) {
            return await apiClient.getFlashSale(productSku: productSku)
        }
    }
}
