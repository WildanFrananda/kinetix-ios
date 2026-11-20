import KinetixDomain
import KinetixPresentation
import SwiftUI

struct ProductDetailContent: View {
    let state: ProductDetailState
    let productReviewsState: ProductReviewsSectionState
    let merchantReviewsState: ProductReviewsSectionState
    let isLoadingMoreProductReviews: Bool
    let isLoadingMoreMerchantReviews: Bool
    let failureMapper: FailureMessageMapper
    let imagePipeline: ImagePipeline?
    let onLoadMoreProductReviews: () -> Void
    let onLoadMoreMerchantReviews: () -> Void
    let onRefresh: () -> Void

    @Environment(\.locale) private var locale
    @State private var selectedReviewTab: ProductReviewSectionTab = .product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                switch state {
                case .idle, .loading:
                    HStack(spacing: KinetixTheme.spacingSmall) {
                        ProgressView()
                            .tint(KinetixPalette.accent)

                        Text(.catalogLoadingLabel)
                            .font(KinetixTypography.body)
                            .foregroundStyle(KinetixPalette.textSecondary)
                    }
                    .padding(KinetixTheme.spacingLarge)
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
                case .notFound:
                    KinetixStatusBanner(
                        tone: .warning,
                        message: .productDetailNotFoundMessage,
                    )
                case .failed(let failure):
                    VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                        KinetixStatusBanner(
                            tone: .danger,
                            message: failureMapper.message(for: failure),
                        )

                        KinetixPrimaryButton(
                            title: .commonRetryButton,
                            action: onRefresh,
                        )
                    }
                case .loaded(let detail, let priceIndication, let flashSale, let isCachedStale):
                    loadedSection(
                        detail: detail,
                        priceIndication: priceIndication,
                        flashSale: flashSale,
                        isCachedStale: isCachedStale,
                    )
                }
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationTitle(Text(.productDetailTitle))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            onRefresh()
        }
    }

    @ViewBuilder
    private func loadedSection(
        detail: ProductDetail,
        priceIndication: PriceIndication,
        flashSale: FlashSale?,
        isCachedStale: Bool,
    ) -> some View {
        if isCachedStale {
            KinetixStatusBanner(
                tone: .warning,
                message: .catalogCachedStaleNotice,
            )
        }

        if let imageURL = detail.imageURL {
            KinetixRemoteImage(
                url: imageURL,
                maxPixelDimension: 720,
                pipeline: imagePipeline,
            )
            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                    .stroke(
                        KinetixPalette.borderHairline,
                        lineWidth: KinetixTheme.borderWidthHairline,
                    )
            )
        }

        VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
            HStack(spacing: KinetixTheme.spacingSmall) {
                Text(detail.categoryName)
                    .font(KinetixTypography.eyebrow)
                    .foregroundStyle(KinetixPalette.textTertiary)
                    .textCase(.uppercase)

                Spacer(minLength: 0)

                Text(detail.sku.value)
                    .font(KinetixTypography.labelMono)
                    .foregroundStyle(KinetixPalette.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(KinetixPalette.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                KinetixPalette.borderHairline,
                                lineWidth: KinetixTheme.borderWidthHairline,
                            )
                    )
            }

            Text(detail.title)
                .font(KinetixTypography.display)
                .foregroundStyle(KinetixPalette.textPrimary)
        }

        priceCard(priceIndication: priceIndication, flashSale: flashSale)

        stockAndSpecCard(detail: detail)

        if !detail.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                KinetixSectionHeader(title: .productDetailDescriptionSection)

                Text(detail.descriptionText)
                    .font(KinetixTypography.body)
                    .foregroundStyle(KinetixPalette.textSecondary)
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
            }
        }

        reviewsSection
    }

    private func priceCard(
        priceIndication: PriceIndication,
        flashSale: FlashSale?,
    ) -> some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
            switch priceIndication.appliedPromotion {
            case .flashSale(let title):
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(KinetixPalette.accent)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(KinetixTypography.fieldLabel)
                        .foregroundStyle(KinetixPalette.accentHigh)

                    Spacer(minLength: 0)

                    if let flashSale {
                        Text(
                            .productDetailFlashRemaining(
                                flashSale.remainingStock,
                                flashSale.stockLimit,
                            )
                        )
                        .font(KinetixTypography.labelMono)
                        .foregroundStyle(KinetixPalette.textTertiary)
                    }
                }
            case .discount(let title):
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(KinetixPalette.accent)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(KinetixTypography.fieldLabel)
                        .foregroundStyle(KinetixPalette.accentHigh)
                }
            case .none:
                EmptyView()
            }

            Text(
                KinetixPriceFormatter.format(
                    amount: priceIndication.finalUnitPrice,
                    currency: priceIndication.currency,
                    locale: locale,
                )
            )
            .font(KinetixTypography.otpCode)
            .foregroundStyle(
                priceIndication.hasSavings
                    ? KinetixPalette.accentHigh
                    : KinetixPalette.textPrimary
            )
            .fixedSize(horizontal: false, vertical: true)

            if priceIndication.hasSavings {
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
            }

            Text(.productDetailIndicativePriceNote)
                .font(KinetixTypography.caption)
                .foregroundStyle(KinetixPalette.textTertiary)
        }
        .padding(KinetixTheme.spacingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KinetixPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                .stroke(
                    priceIndication.hasSavings
                        ? KinetixPalette.accent.opacity(0.45)
                        : KinetixPalette.borderHairline,
                    lineWidth: KinetixTheme.borderWidthHairline,
                )
        )
    }

    private func stockAndSpecCard(detail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
            KinetixSectionHeader(title: .productDetailWarehouseSection)

            VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                HStack {
                    KinetixStockBadge(
                        status: detail.warehouseStock.stockStatus,
                        availableQuantity: detail.warehouseStock.availableQuantity,
                    )

                    Spacer(minLength: 0)

                    if let weightGrams = detail.weightGrams {
                        Text(.productDetailWeightGrams(weightGrams))
                            .font(KinetixTypography.labelMono)
                            .foregroundStyle(KinetixPalette.textSecondary)
                    }
                }

                if detail.warehouseStock.stockStatus == .unknown {
                    Text(.productDetailStockUnknownExplanation)
                        .font(KinetixTypography.subheadline)
                        .foregroundStyle(KinetixPalette.textSecondary)
                } else {
                    HStack(spacing: KinetixTheme.spacingMedium) {
                        if let bin = detail.warehouseStock.binLocation {
                            Text(.productDetailBinLocation(bin))
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.textTertiary)
                        }

                        if let reserved = detail.warehouseStock.reservedQuantity {
                            Text(.productDetailReservedCount(reserved))
                                .font(KinetixTypography.labelMono)
                                .foregroundStyle(KinetixPalette.textTertiary)
                        }
                    }
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
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
            KinetixSectionHeader(title: .productDetailReviewsSection)

            Picker("", selection: $selectedReviewTab) {
                Text(.productDetailTabProductReviews).tag(ProductReviewSectionTab.product)
                Text(.productDetailTabMerchantReviews).tag(ProductReviewSectionTab.merchant)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text(.productDetailReviewsSection))

            switch selectedReviewTab {
            case .product:
                reviewTabBody(
                    sectionState: productReviewsState,
                    isLoadingMore: isLoadingMoreProductReviews,
                    onLoadMore: onLoadMoreProductReviews,
                )
            case .merchant:
                reviewTabBody(
                    sectionState: merchantReviewsState,
                    isLoadingMore: isLoadingMoreMerchantReviews,
                    onLoadMore: onLoadMoreMerchantReviews,
                )
            }
        }
    }

    @ViewBuilder
    private func reviewTabBody(
        sectionState: ProductReviewsSectionState,
        isLoadingMore: Bool,
        onLoadMore: @escaping () -> Void,
    ) -> some View {
        switch sectionState {
        case .loading:
            HStack(spacing: KinetixTheme.spacingSmall) {
                ProgressView()
                    .tint(KinetixPalette.accent)

                Text(.productDetailReviewsLoading)
                    .font(KinetixTypography.subheadline)
                    .foregroundStyle(KinetixPalette.textSecondary)
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
        case .failed(let failure):
            KinetixStatusBanner(
                tone: .warning,
                message: failureMapper.message(for: failure),
            )
        case .loaded(let page):
            VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                HStack(spacing: KinetixTheme.spacingSmall) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(KinetixPalette.accent)
                        .accessibilityHidden(true)

                    Text(
                        page.averageRating.formatted(
                            .number.precision(.fractionLength(0...2))
                        )
                    )
                    .font(KinetixTypography.priceMono)
                    .foregroundStyle(KinetixPalette.textPrimary)

                    Text(.productDetailReviewsCount(page.totalReviews))
                        .font(KinetixTypography.subheadline)
                        .foregroundStyle(KinetixPalette.textTertiary)
                }

                if page.items.isEmpty {
                    Text(.productDetailReviewsEmpty)
                        .font(KinetixTypography.subheadline)
                        .foregroundStyle(KinetixPalette.textSecondary)
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
                } else {
                    ForEach(page.items, id: \.id) { review in
                        VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(
                                            star <= review.rating
                                                ? KinetixPalette.accent
                                                : KinetixPalette.textMuted
                                        )
                                }

                                Spacer(minLength: 0)

                                Text(review.productSku.value)
                                    .font(KinetixTypography.labelMono)
                                    .foregroundStyle(KinetixPalette.textTertiary)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(.productDetailReviewRating(review.rating)))

                            if let comment = review.comment,
                                !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            {
                                Text(comment)
                                    .font(KinetixTypography.body)
                                    .foregroundStyle(KinetixPalette.textPrimary)
                            } else {
                                Text(.productDetailReviewNoComment)
                                    .font(KinetixTypography.subheadline)
                                    .foregroundStyle(KinetixPalette.textTertiary)
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
                    }

                    if page.hasNextPage {
                        KinetixPrimaryButton(
                            title: .productDetailLoadMoreReviewsButton,
                            isLoading: isLoadingMore,
                            isDisabled: isLoadingMore,
                            action: onLoadMore,
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailContent(
            state: .loading,
            productReviewsState: .loading,
            merchantReviewsState: .loading,
            isLoadingMoreProductReviews: false,
            isLoadingMoreMerchantReviews: false,
            failureMapper: FailureMessageMapper(),
            imagePipeline: nil,
            onLoadMoreProductReviews: {},
            onLoadMoreMerchantReviews: {},
            onRefresh: {},
        )
    }
    .preferredColorScheme(.dark)
}
