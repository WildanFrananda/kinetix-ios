import Foundation

public protocol CatalogRepository: Sendable {
    func listCategories() async -> Result<CatalogFetchOutcome<[ProductCategory]>, Failure>

    func listProducts(
        query: ProductListQuery
    ) async -> Result<CatalogFetchOutcome<ProductPage>, Failure>

    func getProduct(
        sku: ProductSku
    ) async -> Result<CatalogFetchOutcome<ProductDetail>, Failure>
}
