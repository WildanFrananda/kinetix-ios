import Foundation
import KinetixDomain

public struct DefaultReviewRepository: ReviewRepository {
    private let apiClient: ReviewAPIClient
    private let productReviewsCoalescer = InFlightReadCoalescer<
        String,
        Result<ReviewPage, Failure>
    >()
    private let merchantReviewsCoalescer = InFlightReadCoalescer<
        String,
        Result<ReviewPage, Failure>
    >()

    public init(apiClient: ReviewAPIClient) {
        self.apiClient = apiClient
    }

    public func listProductReviews(
        productSku: ProductSku,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        let apiClient = self.apiClient
        let clampedPage = max(1, page)
        let key = "\(productSku.value)|\(clampedPage)"

        return await productReviewsCoalescer.coalesce(key: key) {
            return await apiClient.listProductReviews(
                productSku: productSku,
                page: clampedPage,
            )
        }
    }

    public func listMerchantReviews(
        merchantPrincipalId: PrincipalId,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        let apiClient = self.apiClient
        let clampedPage = max(1, page)
        let key = "\(merchantPrincipalId.value)|\(clampedPage)"

        return await merchantReviewsCoalescer.coalesce(key: key) {
            return await apiClient.listMerchantReviews(
                merchantPrincipalId: merchantPrincipalId,
                page: clampedPage,
            )
        }
    }
}
