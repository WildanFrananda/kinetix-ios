import Foundation

public protocol ReviewRepository: Sendable {
    func listProductReviews(
        productSku: ProductSku,
        page: Int,
    ) async -> Result<ReviewPage, Failure>

    func listMerchantReviews(
        merchantPrincipalId: PrincipalId,
        page: Int,
    ) async -> Result<ReviewPage, Failure>
}
