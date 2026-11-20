import Foundation
import KinetixDomain
import Synchronization

public final class FakePricingRepository: PricingRepository {
    private let discountsResultMutex = Mutex<Result<[PromotionDiscount], Failure>>(
        .success([])
    )
    private let flashSaleResultMutex = Mutex<Result<FlashSale?, Failure>>(.success(nil))

    public init() {}

    public func setDiscountsResult(_ result: Result<[PromotionDiscount], Failure>) {
        discountsResultMutex.withLock { $0 = result }
    }

    public func setFlashSaleResult(_ result: Result<FlashSale?, Failure>) {
        flashSaleResultMutex.withLock { $0 = result }
    }

    public func listDiscounts() async -> Result<[PromotionDiscount], Failure> {
        return discountsResultMutex.withLock { $0 }
    }

    public func getFlashSale(productSku: ProductSku) async -> Result<FlashSale?, Failure> {
        return flashSaleResultMutex.withLock { $0 }
    }
}
