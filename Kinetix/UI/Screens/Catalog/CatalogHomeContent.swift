import KinetixDomain
import KinetixPresentation
import SwiftUI

struct CatalogHomeContent: View {
    let state: CatalogHomeState
    let categories: [ProductCategory]
    let selectedCategorySlug: CategorySlug?
    let products: [ProductSummary]
    let isShowingCachedStale: Bool
    let isLoadingNextPage: Bool
    let paginationFailure: Failure?
    let isAuthenticated: Bool
    let failureMapper: FailureMessageMapper
    let imagePipeline: ImagePipeline?
    let priceIndicationProvider: (ProductSummary) -> PriceIndication
    let onSelectCategory: (CategorySlug?) -> Void
    let onOpenSearch: () -> Void
    let onOpenLanguageSettings: () -> Void
    let onOpenAccountOrSignIn: () -> Void
    let onSelectProduct: (ProductSku) -> Void
    let onLoadNextPage: (ProductSku) -> Void
    let onRetryNextPage: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingLarge) {
                headerBar

                if !categories.isEmpty || selectedCategorySlug != nil {
                    categoryFilterRow
                }

                if isShowingCachedStale {
                    KinetixStatusBanner(
                        tone: .warning,
                        message: .catalogCachedStaleNotice,
                    )
                }

                mainSection
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .background(KinetixPalette.background.ignoresSafeArea())
        .refreshable {
            onRefresh()
        }
    }

    private var headerBar: some View {
        HStack(spacing: KinetixTheme.spacingSmall) {
            KinetixBrandHeader()

            Spacer(minLength: 0)

            Button(action: onOpenSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .frame(
                        width: KinetixTheme.minTapTarget,
                        height: KinetixTheme.minTapTarget,
                    )
                    .background(KinetixPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .stroke(
                                KinetixPalette.borderHairline,
                                lineWidth: KinetixTheme.borderWidthHairline,
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.searchTitle))

            Button(action: onOpenLanguageSettings) {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .frame(
                        width: KinetixTheme.minTapTarget,
                        height: KinetixTheme.minTapTarget,
                    )
                    .background(KinetixPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .stroke(
                                KinetixPalette.borderHairline,
                                lineWidth: KinetixTheme.borderWidthHairline,
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.languageSettingsTitle))

            Button(action: onOpenAccountOrSignIn) {
                Image(
                    systemName: isAuthenticated
                        ? "person.crop.circle.fill"
                        : "person.crop.circle"
                )
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    isAuthenticated
                        ? KinetixPalette.accentHigh
                        : KinetixPalette.textPrimary
                )
                .frame(
                    width: KinetixTheme.minTapTarget,
                    height: KinetixTheme.minTapTarget,
                )
                .background(
                    isAuthenticated
                        ? KinetixPalette.accentLow
                        : KinetixPalette.surface
                )
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                        .stroke(
                            isAuthenticated
                                ? KinetixPalette.accent.opacity(0.5)
                                : KinetixPalette.borderHairline,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(isAuthenticated ? .accountTitle : .authSignInTitle)
            )
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KinetixTheme.spacingSmall) {
                categoryChip(
                    title: Text(.catalogAllCategoriesChip),
                    isSelected: selectedCategorySlug == nil,
                    action: {
                        onSelectCategory(nil)
                    },
                )

                ForEach(categories, id: \.slug) { category in
                    categoryChip(
                        title: Text(category.name),
                        isSelected: selectedCategorySlug == category.slug,
                        action: {
                            onSelectCategory(category.slug)
                        },
                    )
                }
            }
        }
    }

    private func categoryChip(
        title: Text,
        isSelected: Bool,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            title
                .font(KinetixTypography.fieldLabel)
                .foregroundStyle(
                    isSelected ? KinetixPalette.accentHigh : KinetixPalette.textSecondary
                )
                .padding(.horizontal, KinetixTheme.spacingMedium)
                .frame(minHeight: KinetixTheme.minTapTarget)
                .background(
                    isSelected ? KinetixPalette.accentLow : KinetixPalette.surface
                )
                .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                        .stroke(
                            isSelected ? KinetixPalette.accent : KinetixPalette.borderHairline,
                            lineWidth: KinetixTheme.borderWidthHairline,
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mainSection: some View {
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
        case .empty:
            VStack(alignment: .leading, spacing: KinetixTheme.spacingSmall) {
                Text(.catalogEmptyTitle)
                    .font(KinetixTypography.title)
                    .foregroundStyle(KinetixPalette.textPrimary)

                Text(.catalogEmptySubtitle)
                    .font(KinetixTypography.subheadline)
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
        case .loaded:
            LazyVStack(spacing: KinetixTheme.spacingMedium) {
                ForEach(products, id: \.sku) { product in
                    CatalogProductCard(
                        product: product,
                        priceIndication: priceIndicationProvider(product),
                        imagePipeline: imagePipeline,
                        onTap: {
                            onSelectProduct(product.sku)
                        },
                    )
                    .onAppear {
                        onLoadNextPage(product.sku)
                    }
                }

                if isLoadingNextPage {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(KinetixPalette.accent)
                        Spacer()
                    }
                    .padding(.vertical, KinetixTheme.spacingMedium)
                }

                if let paginationFailure {
                    VStack(spacing: KinetixTheme.spacingSmall) {
                        KinetixStatusBanner(
                            tone: .warning,
                            message: failureMapper.message(for: paginationFailure),
                        )

                        KinetixPrimaryButton(
                            title: .commonRetryButton,
                            action: onRetryNextPage,
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    CatalogHomeContent(
        state: .empty,
        categories: [],
        selectedCategorySlug: nil,
        products: [],
        isShowingCachedStale: false,
        isLoadingNextPage: false,
        paginationFailure: nil,
        isAuthenticated: false,
        failureMapper: FailureMessageMapper(),
        imagePipeline: nil,
        priceIndicationProvider: { product in
            PriceIndication(
                basePrice: product.price,
                finalUnitPrice: product.price,
                savingsPerUnit: 0,
                currency: product.currency,
                appliedPromotion: .none,
            )
        },
        onSelectCategory: { _ in },
        onOpenSearch: {},
        onOpenLanguageSettings: {},
        onOpenAccountOrSignIn: {},
        onSelectProduct: { _ in },
        onLoadNextPage: { _ in },
        onRetryNextPage: {},
        onRefresh: {},
    )
    .preferredColorScheme(.dark)
}
