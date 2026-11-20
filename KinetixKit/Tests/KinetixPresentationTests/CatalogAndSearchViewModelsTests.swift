import Foundation
import KinetixDomain
import KinetixFakes
import KinetixPresentation
import Testing

struct CatalogAndSearchViewModelsTests {
    @Test
    func catalogHomeLoadsOnceFiltersByCategoryPaginatesAndComputesPriceIndications() async throws {
        let sku1 = try #require(ProductSku("KAOS-HITAM-M"))
        let sku2 = try #require(ProductSku("KAOS-PUTIH-L"))
        let categorySlug = try #require(CategorySlug("pakaian"))
        let merchantId = try #require(PrincipalId("3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d"))

        let product1 = ProductSummary(
            id: 1,
            sku: sku1,
            title: "Kaos Hitam",
            categoryName: "Pakaian",
            categorySlug: categorySlug,
            price: Decimal(100_000),
            currency: "IDR",
            imageURL: nil,
            merchantPrincipalId: merchantId,
            weightGrams: 250,
            availableStock: 10,
            isInStock: true,
            stockStatus: .inStock,
        )
        let product2 = ProductSummary(
            id: 2,
            sku: sku2,
            title: "Kaos Putih",
            categoryName: "Pakaian",
            categorySlug: categorySlug,
            price: Decimal(120_000),
            currency: "IDR",
            imageURL: nil,
            merchantPrincipalId: merchantId,
            weightGrams: nil,
            availableStock: nil,
            isInStock: nil,
            stockStatus: .unknown,
        )

        let catalogRepo = FakeCatalogRepository()
        let pricingRepo = FakePricingRepository()
        catalogRepo.setCategoriesResult(
            .success(
                .fresh([
                    ProductCategory(id: 3, name: "Pakaian", slug: categorySlug)
                ])
            )
        )
        catalogRepo.setListProductsResult(
            .success(
                .cachedStale(
                    ProductPage(
                        totalCount: 40,
                        page: 1,
                        pageSize: 20,
                        items: [product1],
                    )
                )
            )
        )
        pricingRepo.setDiscountsResult(
            .success([
                PromotionDiscount(
                    id: "d1",
                    title: "Diskon 10%",
                    discountType: .percentage,
                    value: Decimal(10),
                    targetProductSku: sku1,
                    targetCategorySlug: nil,
                    active: true,
                    startTime: Date(timeIntervalSince1970: 1_700_000_000),
                    endTime: Date(timeIntervalSince1970: 1_800_000_000),
                    merchantPrincipalId: merchantId,
                )
            ])
        )

        let viewModel = CatalogHomeViewModel(
            catalogRepository: catalogRepo,
            pricingRepository: pricingRepo,
        )
        viewModel.start()
        try? await Task.sleep(for: .milliseconds(25))

        #expect(viewModel.state == .loaded)
        #expect(viewModel.isShowingCachedStale)
        #expect(viewModel.products.count == 1)
        #expect(viewModel.priceIndication(for: product1).finalUnitPrice == Decimal(90_000))

        viewModel.start()
        try? await Task.sleep(for: .milliseconds(15))
        #expect(catalogRepo.listProductsQueries().count == 1)

        catalogRepo.setListProductsResult(
            .success(
                .fresh(
                    ProductPage(
                        totalCount: 40,
                        page: 2,
                        pageSize: 20,
                        items: [product1, product2],
                    )
                )
            )
        )
        viewModel.loadNextPageIfNeeded(currentSku: sku1)
        try? await Task.sleep(for: .milliseconds(25))
        #expect(viewModel.products.map(\.sku) == [sku1, sku2])
    }

    @Test
    func searchViewModelDebouncesSuggestionsAndProductDetailPrioritizesFlashSale() async throws {
        let sku = try #require(ProductSku("KAOS-HITAM-M"))
        let categorySlug = try #require(CategorySlug("pakaian"))
        let merchantId = try #require(PrincipalId("3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d"))

        let searchRepo = FakeSearchRepository()
        let catalogRepo = FakeCatalogRepository()
        let clock = FakeAppClock()
        searchRepo.setSuggestResult(.success(["Kaos Polos Hitam M"]))
        searchRepo.setSearchResult(
            .success(
                SearchResponse(
                    totalCount: 1,
                    hits: [
                        SearchHit(
                            sku: sku,
                            merchantPrincipalId: merchantId,
                            title: "Kaos Polos Hitam M",
                            descriptionText: nil,
                            categorySlugs: [categorySlug],
                            priceMinor: 8_900_000,
                            currency: "IDR",
                            updatedAtMillis: 1_792_572_000_000,
                        )
                    ],
                    categoryFacets: [
                        SearchCategoryFacet(categorySlug: categorySlug, count: 1)
                    ],
                    indexStatus: SearchIndexStatus(
                        indexedThroughMillis: nil,
                        ageSeconds: nil,
                        isStale: true,
                    ),
                )
            )
        )

        let searchVM = SearchViewModel(
            searchRepository: searchRepo,
            catalogRepository: catalogRepo,
            clock: clock,
        )
        searchVM.onQueryTextChanged("kao")
        searchVM.onQueryTextChanged("kaos")
        try? await Task.sleep(for: .milliseconds(25))
        #expect(searchRepo.suggestCalls() == ["kaos"])
        #expect(searchVM.suggestions == ["Kaos Polos Hitam M"])

        searchVM.pickSuggestion("Kaos Polos Hitam M")
        try? await Task.sleep(for: .milliseconds(25))
        #expect(searchVM.suggestions.isEmpty)
        if case .results(let response) = searchVM.state {
            #expect(response.indexStatus.isStale)
        } else {
            Issue.record("Expected search results state")
        }

        let pricingRepo = FakePricingRepository()
        let reviewRepo = FakeReviewRepository()
        let detail = ProductDetail(
            id: 42,
            sku: sku,
            title: "Kaos Polos Hitam M",
            descriptionText: "Katun combed 30s",
            categoryName: "Pakaian",
            categorySlug: categorySlug,
            price: Decimal(89_000),
            currency: "IDR",
            imageURL: nil,
            merchantPrincipalId: merchantId,
            weightGrams: 250,
            warehouseStock: WarehouseStock(
                sku: sku,
                binLocation: "A-01",
                availableQuantity: 12,
                reservedQuantity: 1,
                stockStatus: .inStock,
            ),
        )
        catalogRepo.setGetProductResult(.success(.fresh(detail)))
        pricingRepo.setFlashSaleResult(
            .success(
                FlashSale(
                    id: "fs-1",
                    title: "Flash Sale Kaos",
                    productSku: sku,
                    flashPrice: Decimal(69_000),
                    stockLimit: 20,
                    stockSold: 5,
                    active: true,
                    startTime: Date(timeIntervalSince1970: 1_700_000_000),
                    endTime: Date(timeIntervalSince1970: 1_800_000_000),
                    merchantPrincipalId: merchantId,
                )
            )
        )
        let detailVM = ProductDetailViewModel(
            sku: sku,
            catalogRepository: catalogRepo,
            pricingRepository: pricingRepo,
            reviewRepository: reviewRepo,
        )
        detailVM.start()
        try? await Task.sleep(for: .milliseconds(25))

        if case .loaded(_, let indication, _, _) = detailVM.state {
            #expect(indication.finalUnitPrice == Decimal(69_000))
            #expect(indication.appliedPromotion == .flashSale(title: "Flash Sale Kaos"))
        } else {
            Issue.record("Expected loaded product detail state")
        }
    }
}
