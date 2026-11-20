import Foundation
import KinetixData
import KinetixDomain

public actor FakeCatalogCacheStore: CatalogCacheStore {
    private var categories: [ProductCategory]?
    private var pagesByKey: [String: ProductPage] = [:]
    private var detailsBySku: [ProductSku: ProductDetail] = [:]

    public init() {}

    public func readCategories() async -> [ProductCategory]? {
        return categories
    }

    public func saveCategories(
        _ categories: [ProductCategory],
        savedAt: Date,
    ) async {
        self.categories = categories
    }

    public func readProductPage(for query: ProductListQuery) async -> ProductPage? {
        return pagesByKey[query.cacheKey]
    }

    public func saveProductPage(
        _ page: ProductPage,
        for query: ProductListQuery,
        savedAt: Date,
    ) async {
        pagesByKey[query.cacheKey] = page
    }

    public func readProductDetail(sku: ProductSku) async -> ProductDetail? {
        return detailsBySku[sku]
    }

    public func saveProductDetail(
        _ detail: ProductDetail,
        savedAt: Date,
    ) async {
        detailsBySku[detail.sku] = detail
    }
}
