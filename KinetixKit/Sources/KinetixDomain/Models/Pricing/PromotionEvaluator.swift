import Foundation

public struct PromotionEvaluator: Sendable {
    public init() {}

    public func matchesDiscount(
        _ discount: PromotionDiscount,
        sku: ProductSku,
        categorySlug: CategorySlug,
        merchantPrincipalId: PrincipalId,
    ) -> Bool {
        guard discount.active else {
            return false
        }

        if let discountMerchant = discount.merchantPrincipalId,
            discountMerchant != merchantPrincipalId
        {
            return false
        }

        let matchesProduct = discount.targetProductSku == sku
        let matchesCategory = discount.targetCategorySlug == categorySlug
        let isGlobal = discount.targetProductSku == nil && discount.targetCategorySlug == nil

        return matchesProduct || matchesCategory || isGlobal
    }

    public func discountSavings(
        for discount: PromotionDiscount,
        basePrice: Decimal,
    ) -> Decimal {
        guard basePrice > 0 else {
            return 0
        }

        let rawSavings: Decimal
        switch discount.discountType {
        case .percentage:
            rawSavings = basePrice * (discount.value / Decimal(100))
        case .fixed:
            rawSavings = discount.value
        case .unknown:
            rawSavings = 0
        }

        return min(max(rawSavings, 0), basePrice)
    }

    public func bestMatchingDiscount(
        from discounts: [PromotionDiscount],
        sku: ProductSku,
        categorySlug: CategorySlug,
        merchantPrincipalId: PrincipalId,
        basePrice: Decimal,
    ) -> PromotionDiscount? {
        var bestSavings: Decimal = 0
        var selectedDiscount: PromotionDiscount?

        for discount in discounts {
            guard
                matchesDiscount(
                    discount,
                    sku: sku,
                    categorySlug: categorySlug,
                    merchantPrincipalId: merchantPrincipalId,
                )
            else {
                continue
            }

            let savings = discountSavings(for: discount, basePrice: basePrice)
            if savings > bestSavings {
                bestSavings = savings
                selectedDiscount = discount
            }
        }

        return selectedDiscount
    }

    public func evaluateIndication(
        basePrice: Decimal,
        currency: String,
        sku: ProductSku,
        categorySlug: CategorySlug,
        merchantPrincipalId: PrincipalId,
        flashSale: FlashSale?,
        discounts: [PromotionDiscount],
    ) -> PriceIndication {
        if let flashSale,
            flashSale.active,
            flashSale.productSku == sku,
            flashSale.merchantPrincipalId == nil
                || flashSale.merchantPrincipalId == merchantPrincipalId,
            flashSale.stockSold < flashSale.stockLimit,
            flashSale.flashPrice >= 0,
            flashSale.flashPrice < basePrice
        {
            return PriceIndication(
                basePrice: basePrice,
                finalUnitPrice: flashSale.flashPrice,
                savingsPerUnit: basePrice - flashSale.flashPrice,
                currency: currency,
                appliedPromotion: .flashSale(title: flashSale.title),
            )
        }

        if let best = bestMatchingDiscount(
            from: discounts,
            sku: sku,
            categorySlug: categorySlug,
            merchantPrincipalId: merchantPrincipalId,
            basePrice: basePrice,
        ) {
            let savings = discountSavings(for: best, basePrice: basePrice)
            let finalPrice = max(basePrice - savings, 0)
            return PriceIndication(
                basePrice: basePrice,
                finalUnitPrice: finalPrice,
                savingsPerUnit: basePrice - finalPrice,
                currency: currency,
                appliedPromotion: .discount(title: best.title),
            )
        }

        return PriceIndication(
            basePrice: basePrice,
            finalUnitPrice: basePrice,
            savingsPerUnit: 0,
            currency: currency,
            appliedPromotion: .none,
        )
    }
}
