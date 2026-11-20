import Foundation
import KinetixDomain
import Synchronization

public final class FakeReviewRepository: ReviewRepository {
    private let productReviewsResultMutex = Mutex<Result<ReviewPage, Failure>>(
        .success(
            ReviewPage(
                averageRating: 0,
                totalReviews: 0,
                items: [],
                currentPage: 1,
                lastPage: 1,
            )
        )
    )
    private let merchantReviewsResultMutex = Mutex<Result<ReviewPage, Failure>>(
        .success(
            ReviewPage(
                averageRating: 0,
                totalReviews: 0,
                items: [],
                currentPage: 1,
                lastPage: 1,
            )
        )
    )
    private let productPagesRequestedMutex = Mutex<[Int]>([])
    private let merchantPagesRequestedMutex = Mutex<[Int]>([])

    public init() {}

    public func setProductReviewsResult(_ result: Result<ReviewPage, Failure>) {
        productReviewsResultMutex.withLock { $0 = result }
    }

    public func setMerchantReviewsResult(_ result: Result<ReviewPage, Failure>) {
        merchantReviewsResultMutex.withLock { $0 = result }
    }

    public func productPagesRequested() -> [Int] {
        return productPagesRequestedMutex.withLock { $0 }
    }

    public func merchantPagesRequested() -> [Int] {
        return merchantPagesRequestedMutex.withLock { $0 }
    }

    public func listProductReviews(
        productSku: ProductSku,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        productPagesRequestedMutex.withLock { $0.append(page) }
        return productReviewsResultMutex.withLock { $0 }
    }

    public func listMerchantReviews(
        merchantPrincipalId: PrincipalId,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        merchantPagesRequestedMutex.withLock { $0.append(page) }
        return merchantReviewsResultMutex.withLock { $0 }
    }
}
