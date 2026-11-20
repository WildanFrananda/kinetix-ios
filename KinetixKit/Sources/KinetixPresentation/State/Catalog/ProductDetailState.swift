import Foundation
import KinetixDomain

nonisolated public enum ProductDetailState: Equatable, Sendable {
    case idle
    case loading
    case loaded(
        detail: ProductDetail,
        priceIndication: PriceIndication,
        flashSale: FlashSale?,
        isCachedStale: Bool,
    )
    case notFound
    case failed(Failure)
}
