import Foundation
import KinetixDomain

public struct DefaultCatalogRepository: CatalogRepository {
    private let apiClient: CatalogAPIClient
    private let cacheStore: any CatalogCacheStore
    private let clock: any AppClock
    private let categoriesCoalescer = InFlightReadCoalescer<
        String,
        Result<CatalogFetchOutcome<[ProductCategory]>, Failure>
    >()
    private let productPagesCoalescer = InFlightReadCoalescer<
        ProductListQuery,
        Result<CatalogFetchOutcome<ProductPage>, Failure>
    >()
    private let productDetailsCoalescer = InFlightReadCoalescer<
        ProductSku,
        Result<CatalogFetchOutcome<ProductDetail>, Failure>
    >()

    public init(
        apiClient: CatalogAPIClient,
        cacheStore: any CatalogCacheStore,
        clock: any AppClock,
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.clock = clock
    }

    public func listCategories() async -> Result<CatalogFetchOutcome<[ProductCategory]>, Failure> {
        let apiClient = self.apiClient
        let cacheStore = self.cacheStore
        let clock = self.clock

        return await categoriesCoalescer.coalesce(key: "categories") {
            let remoteResult = await apiClient.listCategories()
            switch remoteResult {
            case .success(let categories):
                await cacheStore.saveCategories(categories, savedAt: clock.now())
                return .success(.fresh(categories))
            case .failure(let failure):
                if Self.shouldFallbackToCache(for: failure),
                    let cached = await cacheStore.readCategories()
                {
                    return .success(.cachedStale(cached))
                }

                return .failure(failure)
            }
        }
    }

    public func listProducts(
        query: ProductListQuery
    ) async -> Result<CatalogFetchOutcome<ProductPage>, Failure> {
        let apiClient = self.apiClient
        let cacheStore = self.cacheStore
        let clock = self.clock

        return await productPagesCoalescer.coalesce(key: query) {
            let remoteResult = await apiClient.listProducts(query: query)
            switch remoteResult {
            case .success(let page):
                await cacheStore.saveProductPage(page, for: query, savedAt: clock.now())
                return .success(.fresh(page))
            case .failure(let failure):
                if Self.shouldFallbackToCache(for: failure),
                    let cached = await cacheStore.readProductPage(for: query)
                {
                    return .success(.cachedStale(cached))
                }

                return .failure(failure)
            }
        }
    }

    public func getProduct(
        sku: ProductSku
    ) async -> Result<CatalogFetchOutcome<ProductDetail>, Failure> {
        let apiClient = self.apiClient
        let cacheStore = self.cacheStore
        let clock = self.clock

        return await productDetailsCoalescer.coalesce(key: sku) {
            let remoteResult = await apiClient.getProduct(sku: sku)
            switch remoteResult {
            case .success(let detail):
                await cacheStore.saveProductDetail(detail, savedAt: clock.now())
                return .success(.fresh(detail))
            case .failure(let failure):
                if Self.shouldFallbackToCache(for: failure),
                    let cached = await cacheStore.readProductDetail(sku: sku)
                {
                    return .success(.cachedStale(cached))
                }

                return .failure(failure)
            }
        }
    }

    private static func shouldFallbackToCache(for failure: Failure) -> Bool {
        switch failure {
        case .networkNotSent, .outcomeUnknown, .serviceUnavailable, .server, .rateLimited:
            return true
        case .validation, .unauthorized, .forbidden, .notFound, .conflict, .unprocessable,
            .sessionExpired, .sessionUnavailable, .ledgerUnavailable, .unreadableResponse,
            .unsupportedAccountRole, .cancelled:
            return false
        }
    }
}
