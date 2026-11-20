import Foundation
import KinetixDomain
import Observation

@Observable
public final class ProductDetailViewModel {
    public let sku: ProductSku
    public private(set) var state: ProductDetailState = .idle
    public private(set) var productReviewsState: ProductReviewsSectionState = .loading
    public private(set) var merchantReviewsState: ProductReviewsSectionState = .loading
    public private(set) var isLoadingMoreProductReviews = false
    public private(set) var isLoadingMoreMerchantReviews = false

    private let catalogRepository: any CatalogRepository
    private let pricingRepository: any PricingRepository
    private let reviewRepository: any ReviewRepository
    private let promotionEvaluator: PromotionEvaluator
    private var currentMerchantId: PrincipalId?
    private var loadTask: Task<Void, Never>?
    private var moreProductReviewsTask: Task<Void, Never>?
    private var moreMerchantReviewsTask: Task<Void, Never>?

    public init(
        sku: ProductSku,
        catalogRepository: any CatalogRepository,
        pricingRepository: any PricingRepository,
        reviewRepository: any ReviewRepository,
        promotionEvaluator: PromotionEvaluator = PromotionEvaluator(),
    ) {
        self.sku = sku
        self.catalogRepository = catalogRepository
        self.pricingRepository = pricingRepository
        self.reviewRepository = reviewRepository
        self.promotionEvaluator = promotionEvaluator
    }

    public func start() {
        guard state == .idle else {
            return
        }

        performLoad()
    }

    public func refresh() {
        performLoad()
    }

    public func loadMoreProductReviews() {
        guard !isLoadingMoreProductReviews,
            case .loaded(let currentPage) = productReviewsState,
            currentPage.hasNextPage
        else {
            return
        }

        isLoadingMoreProductReviews = true
        let nextPage = currentPage.currentPage + 1
        let targetSku = sku

        moreProductReviewsTask?.cancel()
        moreProductReviewsTask = Task {
            let result = await reviewRepository.listProductReviews(
                productSku: targetSku,
                page: nextPage,
            )
            guard !Task.isCancelled else {
                isLoadingMoreProductReviews = false
                return
            }

            isLoadingMoreProductReviews = false
            if case .success(let newPage) = result {
                var existingIds = Set(currentPage.items.map(\.id))
                var combined = currentPage.items
                for item in newPage.items where existingIds.insert(item.id).inserted {
                    combined.append(item)
                }

                let merged = ReviewPage(
                    averageRating: newPage.averageRating,
                    totalReviews: newPage.totalReviews,
                    items: combined,
                    currentPage: newPage.currentPage,
                    lastPage: newPage.lastPage,
                )
                productReviewsState = .loaded(merged)
            }
        }
    }

    public func loadMoreMerchantReviews() {
        guard !isLoadingMoreMerchantReviews,
            let merchantId = currentMerchantId,
            case .loaded(let currentPage) = merchantReviewsState,
            currentPage.hasNextPage
        else {
            return
        }

        isLoadingMoreMerchantReviews = true
        let nextPage = currentPage.currentPage + 1

        moreMerchantReviewsTask?.cancel()
        moreMerchantReviewsTask = Task {
            let result = await reviewRepository.listMerchantReviews(
                merchantPrincipalId: merchantId,
                page: nextPage,
            )
            guard !Task.isCancelled else {
                isLoadingMoreMerchantReviews = false
                return
            }

            isLoadingMoreMerchantReviews = false
            if case .success(let newPage) = result {
                var existingIds = Set(currentPage.items.map(\.id))
                var combined = currentPage.items
                for item in newPage.items where existingIds.insert(item.id).inserted {
                    combined.append(item)
                }

                let merged = ReviewPage(
                    averageRating: newPage.averageRating,
                    totalReviews: newPage.totalReviews,
                    items: combined,
                    currentPage: newPage.currentPage,
                    lastPage: newPage.lastPage,
                )
                merchantReviewsState = .loaded(merged)
            }
        }
    }

    private func performLoad() {
        loadTask?.cancel()
        moreProductReviewsTask?.cancel()
        moreMerchantReviewsTask?.cancel()
        isLoadingMoreProductReviews = false
        isLoadingMoreMerchantReviews = false

        if case .idle = state {
            state = .loading
        } else if case .failed = state {
            state = .loading
        }

        let targetSku = sku
        loadTask = Task {
            async let productTask = catalogRepository.getProduct(sku: targetSku)
            async let flashSaleTask = pricingRepository.getFlashSale(productSku: targetSku)
            async let discountsTask = pricingRepository.listDiscounts()
            async let productReviewsTask = reviewRepository.listProductReviews(
                productSku: targetSku,
                page: 1,
            )

            let productResult = await productTask
            let flashSaleResult = await flashSaleTask
            let discountsResult = await discountsTask
            let productReviewsResult = await productReviewsTask

            guard !Task.isCancelled else {
                return
            }

            switch productResult {
            case .failure(let failure):
                if failure == .cancelled {
                    return
                }

                if failure == .notFound {
                    state = .notFound
                } else {
                    state = .failed(failure)
                }

                return
            case .success(let outcome):
                let detail = outcome.value
                currentMerchantId = detail.merchantPrincipalId

                let flashSale: FlashSale?
                if case .success(let sale) = flashSaleResult {
                    flashSale = sale
                } else {
                    flashSale = nil
                }

                let discounts: [PromotionDiscount]
                if case .success(let list) = discountsResult {
                    discounts = list
                } else {
                    discounts = []
                }

                let indication = promotionEvaluator.evaluateIndication(
                    basePrice: detail.price,
                    currency: detail.currency,
                    sku: detail.sku,
                    categorySlug: detail.categorySlug,
                    merchantPrincipalId: detail.merchantPrincipalId,
                    flashSale: flashSale,
                    discounts: discounts,
                )

                state = .loaded(
                    detail: detail,
                    priceIndication: indication,
                    flashSale: flashSale,
                    isCachedStale: outcome.isCachedStale,
                )

                switch productReviewsResult {
                case .success(let reviews):
                    productReviewsState = .loaded(reviews)
                case .failure(let failure):
                    if failure != .cancelled {
                        productReviewsState = .failed(failure)
                    }
                }

                let merchantReviewsResult = await reviewRepository.listMerchantReviews(
                    merchantPrincipalId: detail.merchantPrincipalId,
                    page: 1,
                )
                guard !Task.isCancelled else {
                    return
                }

                switch merchantReviewsResult {
                case .success(let reviews):
                    merchantReviewsState = .loaded(reviews)
                case .failure(let failure):
                    if failure != .cancelled {
                        merchantReviewsState = .failed(failure)
                    }
                }
            }
        }
    }
}
