import Foundation
import KinetixData
import KinetixDomain
import KinetixFakes
import Testing

struct WireDecimalAndCatalogRepositoryTests {
    @Test(
        arguments: [
            ("193800.55", "193800.55"),
            ("202000.00", "202000"),
            ("85000", "85000"),
        ]
    )
    func decodesMoneyFromJSONNumbersAndDecimalStringsExactly(
        jsonNumberLiteral: String,
        expectedDecimalString: String,
    ) throws {
        let expected = try #require(WireDecimal.parse(expectedDecimalString))
        let jsonData = Data("[\(jsonNumberLiteral)]".utf8)
        let decodedNumbers = try JSONDecoder().decode([Decimal].self, from: jsonData)
        #expect(decodedNumbers.first == expected)
        #expect(WireDecimal.parse(jsonNumberLiteral) == expected)
    }

    @Test
    func catalogRepositoryWritesThroughToCacheServesStaleOnOutageAndCoalescesInFlightReads()
        async throws
    {
        let transport = FakeHTTPTransport(delayNanoseconds: 5_000_000)
        let vault = FakeSessionVault()
        let clock = FakeAppClock()
        let refreshTransport = TokenRefreshTransport(transport: transport, clock: clock)
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: refreshTransport,
            clock: clock,
        )
        let caller = SafeApiCaller(transport: transport, sessionRenewer: renewer)
        let client = CatalogAPIClient(apiCaller: caller)
        let cache = FakeCatalogCacheStore()
        let repository = DefaultCatalogRepository(
            apiClient: client,
            cacheStore: cache,
            clock: clock,
        )

        let productsJSON = """
            {
              "count": 2,
              "page": 1,
              "page_size": 20,
              "results": [
                {
                  "id": 42,
                  "sku": "KAOS-HITAM-M",
                  "title": "Kaos Polos Hitam M",
                  "category": "Pakaian",
                  "category_slug": "pakaian",
                  "price": "89000.00",
                  "currency": "IDR",
                  "image_url": "",
                  "merchant_principal_id": "3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d",
                  "weight_grams": null,
                  "available_stock": null,
                  "is_in_stock": null,
                  "stock_status": "unknown"
                }
              ]
            }
            """
        transport.enqueue(
            .success(
                HTTPResponse(
                    statusCode: 200,
                    headers: [:],
                    body: Data(productsJSON.utf8),
                    requestId: "req-1",
                )
            )
        )

        let query = ProductListQuery(page: 1, pageSize: 20)
        async let callA = repository.listProducts(query: query)
        async let callB = repository.listProducts(query: query)
        let (resultA, resultB) = await (callA, callB)

        #expect(transport.sentRequests().count == 1)
        let outcome = try resultA.get()
        #expect(resultB == resultA)
        #expect(!outcome.isCachedStale)
        #expect(outcome.value.items.first?.stockStatus == .unknown)
        #expect(outcome.value.items.first?.availableStock == nil)
        #expect(outcome.value.items.first?.imageURL == nil)

        let offlineResult = await repository.listProducts(query: query)
        let offlineOutcome = try offlineResult.get()
        #expect(offlineOutcome.isCachedStale)
        #expect(offlineOutcome.value.items.count == 1)

        let sku = try #require(ProductSku("MISSING-SKU"))
        transport.enqueue(
            .success(
                HTTPResponse(
                    statusCode: 404,
                    headers: [:],
                    body: Data(#"{"error":"PRODUCT_NOT_FOUND","message":"no product"}"#.utf8),
                    requestId: "req-2",
                )
            )
        )
        let notFoundResult = await repository.getProduct(sku: sku)
        #expect(notFoundResult == .failure(.notFound))
    }

    @Test
    func pricingSearchAndReviewRepositoriesDecodeNullableAndStaleContracts() async throws {
        let transport = FakeHTTPTransport()
        let vault = FakeSessionVault()
        let clock = FakeAppClock()
        let refreshTransport = TokenRefreshTransport(transport: transport, clock: clock)
        let renewer = SessionRenewer(
            vault: vault,
            refreshTransport: refreshTransport,
            clock: clock,
        )
        let caller = SafeApiCaller(transport: transport, sessionRenewer: renewer)

        let pricingRepo = DefaultPricingRepository(apiClient: PricingAPIClient(apiCaller: caller))
        let searchRepo = DefaultSearchRepository(apiClient: SearchAPIClient(apiCaller: caller))
        let reviewRepo = DefaultReviewRepository(apiClient: ReviewAPIClient(apiCaller: caller))

        let sku = try #require(ProductSku("KAOS-HITAM-M"))
        transport.enqueue(
            .success(
                HTTPResponse(
                    statusCode: 200,
                    headers: [:],
                    body: Data("null".utf8),
                    requestId: "req-3",
                )
            )
        )
        let flashResult = await pricingRepo.getFlashSale(productSku: sku)
        #expect(try flashResult.get() == nil)

        let blankSuggest = await searchRepo.suggestProducts(queryText: "   ", limit: 5)
        #expect(try blankSuggest.get().isEmpty)
        #expect(transport.sentRequests().count == 1)

        let searchJSON = """
            {
              "total": 1,
              "hits": [
                {
                  "id": "KAOS-HITAM-M",
                  "merchant_id": "3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d",
                  "title": "Kaos Polos Hitam M",
                  "price_minor": 8900000,
                  "currency": "IDR",
                  "updated_at_ms": 1792572000000
                }
              ],
              "index": {
                "indexed_through_ms": null,
                "age_seconds": null,
                "stale": true
              }
            }
            """
        transport.enqueue(
            .success(
                HTTPResponse(
                    statusCode: 200,
                    headers: [:],
                    body: Data(searchJSON.utf8),
                    requestId: "req-4",
                )
            )
        )
        let searchResult = await searchRepo.searchProducts(query: SearchQuery(queryText: "kaos"))
        let searchResponse = try searchResult.get()
        #expect(searchResponse.indexStatus.isStale)
        #expect(searchResponse.hits.first?.indicativePriceMajor == Decimal(89_000))

        let reviewJSON = """
            {
              "product_id": "KAOS-HITAM-M",
              "average_rating": 4.5,
              "total_reviews": 1,
              "data": [
                {
                  "id": "0199f2c1-8d3e-7a4b-b5c6-7d8e9f0a1b2c",
                  "product_id": "KAOS-HITAM-M",
                  "rating": 4,
                  "comment": null,
                  "created_at": "2026-10-17T09:42:11.000000Z",
                  "updated_at": "2026-10-17T09:42:11.000000Z",
                  "merchant_principal_id": "5b2e8c1d-7a4f-4e6b-8c9d-1f3a5b7c9e2d"
                }
              ],
              "current_page": 1,
              "last_page": 1
            }
            """
        transport.enqueue(
            .success(
                HTTPResponse(
                    statusCode: 200,
                    headers: [:],
                    body: Data(reviewJSON.utf8),
                    requestId: "req-5",
                )
            )
        )
        let reviewPage = try await reviewRepo.listProductReviews(productSku: sku, page: 1).get()
        #expect(reviewPage.items.first?.comment == nil)
        #expect(reviewPage.totalReviews == 1)
    }
}
