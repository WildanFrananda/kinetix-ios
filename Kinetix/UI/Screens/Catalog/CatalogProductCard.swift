import KinetixDomain
import SwiftUI

struct CatalogProductCard: View {
    let product: ProductSummary
    let priceIndication: PriceIndication
    let imagePipeline: ImagePipeline?
    let onTap: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: KinetixTheme.spacingMedium) {
                KinetixRemoteImage(
                    url: product.imageURL,
                    maxPixelDimension: 260,
                    pipeline: imagePipeline,
                )
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                        .stroke(
                            KinetixPalette.borderHairline,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )

                VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                    HStack(spacing: KinetixTheme.spacingXSmall) {
                        Text(product.categoryName)
                            .font(KinetixTypography.caption)
                            .foregroundStyle(KinetixPalette.textTertiary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Text(product.sku.value)
                            .font(KinetixTypography.labelMono)
                            .foregroundStyle(KinetixPalette.textMuted)
                            .lineLimit(1)
                    }

                    Text(product.title)
                        .font(KinetixTypography.title)
                        .foregroundStyle(KinetixPalette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    priceSection

                    HStack(spacing: KinetixTheme.spacingSmall) {
                        KinetixStockBadge(
                            status: product.stockStatus,
                            availableQuantity: product.availableStock,
                        )

                        Spacer(minLength: 0)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(KinetixTheme.spacingMedium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KinetixPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                    .stroke(
                        KinetixPalette.borderHairline,
                        lineWidth: KinetixTheme.borderWidthHairline,
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(
                KinetixPriceFormatter.format(
                    amount: priceIndication.finalUnitPrice,
                    currency: priceIndication.currency,
                    locale: locale,
                )
            )
            .font(KinetixTypography.priceMono)
            .foregroundStyle(
                priceIndication.hasSavings
                    ? KinetixPalette.accentHigh
                    : KinetixPalette.textPrimary
            )
            .fixedSize(horizontal: false, vertical: true)

            if priceIndication.hasSavings {
                HStack(spacing: KinetixTheme.spacingXSmall) {
                    Text(
                        KinetixPriceFormatter.format(
                            amount: priceIndication.basePrice,
                            currency: priceIndication.currency,
                            locale: locale,
                        )
                    )
                    .font(KinetixTypography.labelMono)
                    .foregroundStyle(KinetixPalette.textTertiary)
                    .strikethrough(true, color: KinetixPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                    if case .discount(let title) = priceIndication.appliedPromotion {
                        Text(title)
                            .font(KinetixTypography.caption)
                            .foregroundStyle(KinetixPalette.accent)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
