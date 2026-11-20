import Foundation
import KinetixDomain

public protocol CatalogCacheStore: Sendable {
    func readCategories() async -> [ProductCategory]?

    func saveCategories(
        _ categories: [ProductCategory],
        savedAt: Date,
    ) async

    func readProductPage(for query: ProductListQuery) async -> ProductPage?

    func saveProductPage(
        _ page: ProductPage,
        for query: ProductListQuery,
        savedAt: Date,
    ) async

    func readProductDetail(sku: ProductSku) async -> ProductDetail?

    func saveProductDetail(
        _ detail: ProductDetail,
        savedAt: Date,
    ) async
}
