import Foundation
import KinetixDomain
import Testing

struct PromotionEvaluatorTests {
    @Test(
        arguments: [
            ("KAOS-HITAM-M", nil, nil, true, true),
            ("OTHER-SKU", nil, nil, true, false),
            (nil, "pakaian", nil, true, true),
            (nil, "footwear", nil, true, false),
            (nil, nil, nil, true, true),
            ("KAOS-HITAM-M", nil, "9d4e1a7b-2c5f-4e8a-b3d6-0f1c2a3b4c5d", true, false),
            ("KAOS-HITAM-M", nil, nil, false, false),
        ]
    )
    func discountMatchingFollowsPricingServiceRules(
        targetSkuRaw: String?,
        targetCategoryRaw: String?,
        discountMerchantRaw: String?,
        isActive: Bool,
        expectedMatch: Bool,
    ) throws {
        let productSku = try #require(ProductSku("KAOS-HITAM-M"))
        let categorySlug = try #require(CategorySlug("pakaian"))
        let merchantId = try #require(PrincipalId("3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d"))

        let discount = PromotionDiscount(
            id: "disc-1",
            title: "Promo",
            discountType: .percentage,
            value: Decimal(15),
            targetProductSku: targetSkuRaw.flatMap(ProductSku.init),
            targetCategorySlug: targetCategoryRaw.flatMap(CategorySlug.init),
            active: isActive,
            startTime: Date(timeIntervalSince1970: 1_700_000_000),
            endTime: Date(timeIntervalSince1970: 1_800_000_000),
            merchantPrincipalId: discountMerchantRaw.flatMap(PrincipalId.init),
        )

        let evaluator = PromotionEvaluator()
        let actual = evaluator.matchesDiscount(
            discount,
            sku: productSku,
            categorySlug: categorySlug,
            merchantPrincipalId: merchantId,
        )
        #expect(actual == expectedMatch)
    }

    @Test(
        arguments: [
            (Decimal(100_000), Decimal(80_000), "Diskon 20%"),
            (Decimal(40_000), Decimal(25_000), "Potongan Rp15.000"),
            (Decimal(10_000), Decimal(0), "Potongan Rp15.000"),
        ]
    )
    func bestDiscountRuleSelectsLargestSingleSavingsAndNeverStacks(
        basePrice: Decimal,
        expectedFinalPrice: Decimal,
        expectedTitle: String,
    ) throws {
        let sku = try #require(ProductSku("KAOS-HITAM-M"))
        let category = try #require(CategorySlug("pakaian"))
        let merchant = try #require(PrincipalId("3b2f8c1d-6e4a-4f7b-9c2d-5a1e8f0b7c3d"))
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_800_000_000)

        let discounts = [
            PromotionDiscount(
                id: "d1",
                title: "Diskon 20%",
                discountType: .percentage,
                value: Decimal(20),
                targetProductSku: sku,
                targetCategorySlug: nil,
                active: true,
                startTime: start,
                endTime: end,
                merchantPrincipalId: merchant,
            ),
            PromotionDiscount(
                id: "d2",
                title: "Potongan Rp15.000",
                discountType: .fixed,
                value: Decimal(15_000),
                targetProductSku: nil,
                targetCategorySlug: category,
                active: true,
                startTime: start,
                endTime: end,
                merchantPrincipalId: nil,
            ),
            PromotionDiscount(
                id: "d3",
                title: "Unknown Type",
                discountType: .unknown,
                value: Decimal(99_000),
                targetProductSku: sku,
                targetCategorySlug: nil,
                active: true,
                startTime: start,
                endTime: end,
                merchantPrincipalId: nil,
            ),
        ]

        let evaluator = PromotionEvaluator()
        let indication = evaluator.evaluateIndication(
            basePrice: basePrice,
            currency: "IDR",
            sku: sku,
            categorySlug: category,
            merchantPrincipalId: merchant,
            flashSale: nil,
            discounts: discounts,
        )

        #expect(indication.finalUnitPrice == expectedFinalPrice)
        #expect(indication.appliedPromotion == .discount(title: expectedTitle))
    }

    @Test(
        arguments: [
            (Decimal(70_000), 10, 50, true, Decimal(70_000), true),
            (Decimal(100_000), 10, 50, true, Decimal(85_000), false),
            (Decimal(120_000), 10, 50, true, Decimal(85_000), false),
            (Decimal(70_000), 50, 50, true, Decimal(85_000), false),
            (Decimal(70_000), 10, 50, false, Decimal(85_000), false),
        ]
    )
    func flashSaleBelowBasePriceOverridesDiscountsAndOtherwiseFallsBack(
        flashPrice: Decimal,
        stockSold: Int,
        stockLimit: Int,
        flashActive: Bool,
        expectedFinalPrice: Decimal,
        expectsFlashSale: Bool,
    ) throws {
        let sku = try #require(ProductSku("SHOES-RUN-42"))
        let category = try #require(CategorySlug("footwear"))
        let merchant = try #require(PrincipalId("3f6c1a2e-9b4d-4e7a-8c5f-2d1e0b9a8c7d"))
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_800_000_000)

        let flashSale = FlashSale(
            id: "fs-1",
            title: "Flash Sale 11.11",
            productSku: sku,
            flashPrice: flashPrice,
            stockLimit: stockLimit,
            stockSold: stockSold,
            active: flashActive,
            startTime: start,
            endTime: end,
            merchantPrincipalId: merchant,
        )
        let discount = PromotionDiscount(
            id: "d-1",
            title: "Diskon 15%",
            discountType: .percentage,
            value: Decimal(15),
            targetProductSku: sku,
            targetCategorySlug: nil,
            active: true,
            startTime: start,
            endTime: end,
            merchantPrincipalId: merchant,
        )

        let evaluator = PromotionEvaluator()
        let indication = evaluator.evaluateIndication(
            basePrice: Decimal(100_000),
            currency: "IDR",
            sku: sku,
            categorySlug: category,
            merchantPrincipalId: merchant,
            flashSale: flashSale,
            discounts: [discount],
        )

        #expect(indication.finalUnitPrice == expectedFinalPrice)
        if expectsFlashSale {
            #expect(indication.appliedPromotion == .flashSale(title: "Flash Sale 11.11"))
        } else {
            #expect(indication.appliedPromotion == .discount(title: "Diskon 15%"))
        }
    }

    @Test
    func phase2TypedIdsAndStockStatusValidateInputs() {
        #expect(ProductSku("  ") == nil)
        #expect(ProductSku("KAOS-HITAM-M")?.value == "KAOS-HITAM-M")
        #expect(CategorySlug("") == nil)
        #expect(CategorySlug("pakaian")?.value == "pakaian")
        #expect(ReviewId("not-a-uuid") == nil)
        #expect(
            ReviewId("019a0b4e-6f2d-7c3a-9b1e-4d5f6a7b8c9d")?.value
                == "019a0b4e-6f2d-7c3a-9b1e-4d5f6a7b8c9d"
        )
        #expect(StockStatus(wireValue: "in_stock") == .inStock)
        #expect(StockStatus(wireValue: "out_of_stock") == .outOfStock)
        #expect(StockStatus(wireValue: "unknown") == .unknown)
        #expect(StockStatus(wireValue: "UNEXPECTED_STATUS") == .unknown)
    }
}
