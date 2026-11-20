import Foundation
import KinetixDomain
import SwiftData

public actor SwiftDataCatalogCacheStore: CatalogCacheStore {
    private static let categoriesKey = "catalog:categories"

    private let factory: SwiftDataCacheContainerFactory
    private let protectedDataProvider: any ProtectedDataStatusProvider
    private var storeActor: CacheStoreActor?

    public init(
        factory: SwiftDataCacheContainerFactory = SwiftDataCacheContainerFactory(),
        protectedDataProvider: any ProtectedDataStatusProvider,
    ) {
        self.factory = factory
        self.protectedDataProvider = protectedDataProvider
    }

    public func readCategories() async -> [ProductCategory]? {
        guard let data = await readData(forKey: Self.categoriesKey) else {
            return nil
        }

        return try? JSONDecoder().decode([ProductCategory].self, from: data)
    }

    public func saveCategories(
        _ categories: [ProductCategory],
        savedAt: Date,
    ) async {
        guard let data = try? JSONEncoder().encode(categories) else {
            return
        }

        await saveData(data, forKey: Self.categoriesKey, savedAt: savedAt)
    }

    public func readProductPage(for query: ProductListQuery) async -> ProductPage? {
        let key = "catalog:page:\(query.cacheKey)"
        guard let data = await readData(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(ProductPage.self, from: data)
    }

    public func saveProductPage(
        _ page: ProductPage,
        for query: ProductListQuery,
        savedAt: Date,
    ) async {
        guard let data = try? JSONEncoder().encode(page) else {
            return
        }

        let key = "catalog:page:\(query.cacheKey)"
        await saveData(data, forKey: key, savedAt: savedAt)
    }

    public func readProductDetail(sku: ProductSku) async -> ProductDetail? {
        let key = "catalog:detail:\(sku.value)"
        guard let data = await readData(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(ProductDetail.self, from: data)
    }

    public func saveProductDetail(
        _ detail: ProductDetail,
        savedAt: Date,
    ) async {
        guard let data = try? JSONEncoder().encode(detail) else {
            return
        }

        let key = "catalog:detail:\(detail.sku.value)"
        await saveData(data, forKey: key, savedAt: savedAt)
    }

    private func readData(forKey key: String) async -> Data? {
        guard let actor = resolveActor() else {
            return nil
        }

        return try? await actor.readCatalogPayload(forKey: key)
    }

    private func saveData(
        _ data: Data,
        forKey key: String,
        savedAt: Date,
    ) async {
        guard let actor = resolveActor() else {
            return
        }

        try? await actor.saveCatalogPayload(
            data,
            forKey: key,
            savedAt: savedAt,
        )
    }

    private func resolveActor() -> CacheStoreActor? {
        guard protectedDataProvider.isProtectedDataAvailable() else {
            return nil
        }

        if let storeActor {
            return storeActor
        }

        guard let container = try? factory.openOrRebuild() else {
            return nil
        }

        let actor = CacheStoreActor(modelContainer: container)
        storeActor = actor
        return actor
    }
}
