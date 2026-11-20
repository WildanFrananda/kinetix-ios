import Foundation
import KinetixDomain
import Synchronization

public final class FakeCatalogRepository: CatalogRepository {
    private let categoriesResultMutex = Mutex<
        Result<CatalogFetchOutcome<[ProductCategory]>, Failure>
    >(.success(.fresh([])))
    private let listProductsResultMutex = Mutex<
        Result<CatalogFetchOutcome<ProductPage>, Failure>
    >(.success(.fresh(ProductPage(totalCount: 0, page: 1, pageSize: 20, items: []))))
    private let getProductResultMutex = Mutex<
        Result<CatalogFetchOutcome<ProductDetail>, Failure>
    >(.failure(.notFound))
    private let listProductsQueriesMutex = Mutex<[ProductListQuery]>([])
    private let getProductSkusMutex = Mutex<[ProductSku]>([])

    public init() {}

    public func setCategoriesResult(
        _ result: Result<CatalogFetchOutcome<[ProductCategory]>, Failure>
    ) {
        categoriesResultMutex.withLock { $0 = result }
    }

    public func setListProductsResult(
        _ result: Result<CatalogFetchOutcome<ProductPage>, Failure>
    ) {
        listProductsResultMutex.withLock { $0 = result }
    }

    public func setGetProductResult(
        _ result: Result<CatalogFetchOutcome<ProductDetail>, Failure>
    ) {
        getProductResultMutex.withLock { $0 = result }
    }

    public func listProductsQueries() -> [ProductListQuery] {
        return listProductsQueriesMutex.withLock { $0 }
    }

    public func getProductSkus() -> [ProductSku] {
        return getProductSkusMutex.withLock { $0 }
    }

    public func listCategories() async -> Result<CatalogFetchOutcome<[ProductCategory]>, Failure> {
        return categoriesResultMutex.withLock { $0 }
    }

    public func listProducts(
        query: ProductListQuery
    ) async -> Result<CatalogFetchOutcome<ProductPage>, Failure> {
        listProductsQueriesMutex.withLock { $0.append(query) }
        return listProductsResultMutex.withLock { $0 }
    }

    public func getProduct(
        sku: ProductSku
    ) async -> Result<CatalogFetchOutcome<ProductDetail>, Failure> {
        getProductSkusMutex.withLock { $0.append(sku) }
        return getProductResultMutex.withLock { $0 }
    }
}
