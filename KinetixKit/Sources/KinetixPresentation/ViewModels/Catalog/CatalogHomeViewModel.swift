import Foundation
import KinetixDomain
import Observation

@Observable
public final class CatalogHomeViewModel {
    private static let defaultPageSize = 20

    public private(set) var state: CatalogHomeState = .idle
    public private(set) var categories: [ProductCategory] = []
    public private(set) var selectedCategorySlug: CategorySlug?
    public private(set) var products: [ProductSummary] = []
    public private(set) var activeDiscounts: [PromotionDiscount] = []
    public private(set) var isShowingCachedStale = false
    public private(set) var isLoadingNextPage = false
    public private(set) var hasNextPage = false
    public private(set) var paginationFailure: Failure?

    private let catalogRepository: any CatalogRepository
    private let pricingRepository: any PricingRepository
    private let promotionEvaluator: PromotionEvaluator
    private var currentPage = 1
    private var loadTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?

    public init(
        catalogRepository: any CatalogRepository,
        pricingRepository: any PricingRepository,
        promotionEvaluator: PromotionEvaluator = PromotionEvaluator(),
    ) {
        self.catalogRepository = catalogRepository
        self.pricingRepository = pricingRepository
        self.promotionEvaluator = promotionEvaluator
    }

    public func start() {
        guard state == .idle else {
            return
        }

        performFullLoad()
    }

    public func refresh() {
        performFullLoad()
    }

    public func selectCategory(_ slug: CategorySlug?) {
        guard selectedCategorySlug != slug else {
            return
        }

        selectedCategorySlug = slug
        performProductsLoad(for: slug)
    }

    public func loadNextPageIfNeeded(currentSku: ProductSku? = nil) {
        guard hasNextPage, !isLoadingNextPage else {
            return
        }

        if let currentSku, let lastSku = products.last?.sku, currentSku != lastSku {
            return
        }

        isLoadingNextPage = true
        paginationFailure = nil
        let targetPage = currentPage + 1
        let categorySlug = selectedCategorySlug

        nextPageTask?.cancel()
        nextPageTask = Task {
            let query = ProductListQuery(
                categorySlug: categorySlug,
                page: targetPage,
                pageSize: Self.defaultPageSize,
            )
            let result = await catalogRepository.listProducts(query: query)
            guard !Task.isCancelled else {
                isLoadingNextPage = false
                return
            }

            isLoadingNextPage = false
            switch result {
            case .failure(let failure):
                if failure != .cancelled {
                    paginationFailure = failure
                }
            case .success(let outcome):
                if outcome.isCachedStale {
                    isShowingCachedStale = true
                }

                let page = outcome.value
                currentPage = page.page
                hasNextPage = page.hasNextPage

                var existingSkus = Set(products.map(\.sku))
                for item in page.items where existingSkus.insert(item.sku).inserted {
                    products.append(item)
                }
            }
        }
    }

    public func priceIndication(for product: ProductSummary) -> PriceIndication {
        return promotionEvaluator.evaluateIndication(
            basePrice: product.price,
            currency: product.currency,
            sku: product.sku,
            categorySlug: product.categorySlug,
            merchantPrincipalId: product.merchantPrincipalId,
            flashSale: nil,
            discounts: activeDiscounts,
        )
    }

    private func performFullLoad() {
        loadTask?.cancel()
        nextPageTask?.cancel()
        isLoadingNextPage = false
        paginationFailure = nil

        if products.isEmpty {
            state = .loading
        }

        let categorySlug = selectedCategorySlug
        loadTask = Task {
            async let categoriesTask = catalogRepository.listCategories()
            async let discountsTask = pricingRepository.listDiscounts()
            let query = ProductListQuery(
                categorySlug: categorySlug,
                page: 1,
                pageSize: Self.defaultPageSize,
            )
            async let productsTask = catalogRepository.listProducts(query: query)

            let categoriesResult = await categoriesTask
            let discountsResult = await discountsTask
            let productsResult = await productsTask

            guard !Task.isCancelled else {
                return
            }

            var staleFlag = false

            if case .success(let catOutcome) = categoriesResult {
                categories = catOutcome.value
                if catOutcome.isCachedStale {
                    staleFlag = true
                }
            }

            if case .success(let discounts) = discountsResult {
                activeDiscounts = discounts
            }

            applyFirstPageResult(productsResult, additionalStaleFlag: staleFlag)
        }
    }

    private func performProductsLoad(for categorySlug: CategorySlug?) {
        loadTask?.cancel()
        nextPageTask?.cancel()
        isLoadingNextPage = false
        paginationFailure = nil
        state = .loading

        loadTask = Task {
            let query = ProductListQuery(
                categorySlug: categorySlug,
                page: 1,
                pageSize: Self.defaultPageSize,
            )
            let result = await catalogRepository.listProducts(query: query)
            guard !Task.isCancelled else {
                return
            }

            applyFirstPageResult(result, additionalStaleFlag: false)
        }
    }

    private func applyFirstPageResult(
        _ result: Result<CatalogFetchOutcome<ProductPage>, Failure>,
        additionalStaleFlag: Bool,
    ) {
        switch result {
        case .failure(let failure):
            if failure == .cancelled {
                return
            }

            if products.isEmpty {
                state = .failed(failure)
            }
        case .success(let outcome):
            let page = outcome.value
            isShowingCachedStale = additionalStaleFlag || outcome.isCachedStale
            currentPage = page.page
            hasNextPage = page.hasNextPage
            products = page.items
            state = page.items.isEmpty ? .empty : .loaded
        }
    }
}
