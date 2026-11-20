import KinetixDomain
import KinetixPresentation
import SwiftUI

struct SearchContent: View {
    let queryText: String
    let suggestions: [String]
    let selectedCategorySlug: CategorySlug?
    let selectedSort: SearchSortOption
    let state: SearchScreenState
    let isLoadingMore: Bool
    let failureMapper: FailureMessageMapper
    let categoryDisplayNameProvider: (CategorySlug) -> String
    let onQueryTextChanged: (String) -> Void
    let onPickSuggestion: (String) -> Void
    let onSelectCategoryFacet: (CategorySlug?) -> Void
    let onSelectSort: (SearchSortOption) -> Void
    let onSubmitSearch: () -> Void
    let onSelectProduct: (ProductSku) -> Void
    let onLoadNextPage: (ProductSku) -> Void

    @Environment(\.locale) private var locale
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                searchBarRow

                if !suggestions.isEmpty {
                    suggestionsCard
                }

                resultsSection
            }
            .padding(.horizontal, KinetixTheme.spacingMedium)
            .padding(.vertical, KinetixTheme.spacingMedium)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinetixPalette.background.ignoresSafeArea())
        .navigationTitle(Text(.searchTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBarRow: some View {
        HStack(spacing: KinetixTheme.spacingSmall) {
            HStack(spacing: KinetixTheme.spacingSmall) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(KinetixPalette.textTertiary)
                    .accessibilityHidden(true)

                TextField(
                    "",
                    text: Binding(
                        get: { queryText },
                        set: { onQueryTextChanged($0) },
                    ),
                    prompt: Text(.searchPlaceholder)
                        .foregroundStyle(KinetixPalette.textTertiary),
                )
                .font(KinetixTypography.body)
                .foregroundStyle(KinetixPalette.textPrimary)
                .tint(KinetixPalette.accent)
                .focused($isSearchFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFieldFocused = false
                    onSubmitSearch()
                }
                .accessibilityLabel(Text(.searchTitle))

                if !queryText.isEmpty {
                    Button {
                        onQueryTextChanged("")
                        onSubmitSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(KinetixPalette.textTertiary)
                            .frame(
                                width: KinetixTheme.minTapTarget,
                                height: KinetixTheme.minTapTarget,
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(.searchClearQueryAccessibility))
                }
            }
            .padding(.leading, KinetixTheme.spacingMedium)
            .padding(.trailing, queryText.isEmpty ? KinetixTheme.spacingMedium : 4)
            .frame(minHeight: KinetixTheme.controlHeight)
            .background(KinetixPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                    .stroke(
                        isSearchFieldFocused
                            ? KinetixPalette.accent
                            : KinetixPalette.borderStrong,
                        lineWidth: isSearchFieldFocused
                            ? KinetixTheme.borderWidthFocused
                            : KinetixTheme.borderWidthHairline,
                    )
            )

            Menu {
                ForEach(SearchSortOption.allCases, id: \.self) { option in
                    Button {
                        onSelectSort(option)
                    } label: {
                        Label(
                            sortLabel(for: option),
                            systemImage: selectedSort == option ? "checkmark" : "",
                        )
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .frame(
                        width: KinetixTheme.controlHeight,
                        height: KinetixTheme.controlHeight,
                    )
                    .background(KinetixPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            .stroke(
                                KinetixPalette.borderStrong,
                                lineWidth: KinetixTheme.borderWidthHairline,
                            )
                    )
            }
            .accessibilityLabel(Text(.searchSortMenuAccessibility))
        }
    }

    private var suggestionsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { offset, suggestion in
                if offset > 0 {
                    Rectangle()
                        .fill(KinetixPalette.borderHairline)
                        .frame(height: KinetixTheme.borderWidthHairline)
                        .padding(.leading, KinetixTheme.spacingMedium)
                }

                Button {
                    isSearchFieldFocused = false
                    onPickSuggestion(suggestion)
                } label: {
                    HStack(spacing: KinetixTheme.spacingSmall) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(KinetixPalette.textTertiary)
                            .accessibilityHidden(true)

                        Text(suggestion)
                            .font(KinetixTypography.body)
                            .foregroundStyle(KinetixPalette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(KinetixPalette.textMuted)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, KinetixTheme.spacingMedium)
                    .frame(minHeight: KinetixTheme.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(KinetixPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusCard)
                .stroke(
                    KinetixPalette.borderStrong,
                    lineWidth: KinetixTheme.borderWidthHairline,
                )
        )
    }

    @ViewBuilder
    private var resultsSection: some View {
        switch state {
        case .idle, .searching:
            HStack(spacing: KinetixTheme.spacingSmall) {
                ProgressView()
                    .tint(KinetixPalette.accent)

                Text(.searchSearchingLabel)
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
                Text(.searchEmptyTitle)
                    .font(KinetixTypography.title)
                    .foregroundStyle(KinetixPalette.textPrimary)

                Text(.searchEmptySubtitle)
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
                    action: onSubmitSearch,
                )
            }
        case .results(let response):
            VStack(alignment: .leading, spacing: KinetixTheme.spacingMedium) {
                if !response.categoryFacets.isEmpty || selectedCategorySlug != nil {
                    facetRow(facets: response.categoryFacets)
                }

                if response.indexStatus.isStale {
                    KinetixStatusBanner(
                        tone: .warning,
                        message: .searchIndexStaleNotice,
                    )
                }

                Text(.searchResultCount(response.totalCount))
                    .font(KinetixTypography.caption)
                    .foregroundStyle(KinetixPalette.textTertiary)

                LazyVStack(spacing: KinetixTheme.spacingMedium) {
                    ForEach(response.hits, id: \.sku) { hit in
                        hitCard(hit: hit)
                            .onAppear {
                                onLoadNextPage(hit.sku)
                            }
                    }

                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(KinetixPalette.accent)
                            Spacer()
                        }
                        .padding(.vertical, KinetixTheme.spacingMedium)
                    }
                }
            }
        }
    }

    private func facetRow(facets: [SearchCategoryFacet]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KinetixTheme.spacingSmall) {
                if selectedCategorySlug != nil {
                    Button {
                        onSelectCategoryFacet(nil)
                    } label: {
                        Text(.catalogAllCategoriesChip)
                            .font(KinetixTypography.fieldLabel)
                            .foregroundStyle(KinetixPalette.textSecondary)
                            .padding(.horizontal, KinetixTheme.spacingMedium)
                            .frame(minHeight: KinetixTheme.minTapTarget)
                            .background(KinetixPalette.surface)
                            .clipShape(
                                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                    .stroke(
                                        KinetixPalette.borderHairline,
                                        lineWidth: KinetixTheme.borderWidthHairline,
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(facets, id: \.categorySlug) { facet in
                    let isSelected = selectedCategorySlug == facet.categorySlug
                    let name = categoryDisplayNameProvider(facet.categorySlug)

                    Button {
                        onSelectCategoryFacet(facet.categorySlug)
                    } label: {
                        Text("\(name) (\(facet.count))")
                            .font(KinetixTypography.fieldLabel)
                            .foregroundStyle(
                                isSelected
                                    ? KinetixPalette.accentHigh
                                    : KinetixPalette.textSecondary
                            )
                            .padding(.horizontal, KinetixTheme.spacingMedium)
                            .frame(minHeight: KinetixTheme.minTapTarget)
                            .background(
                                isSelected ? KinetixPalette.accentLow : KinetixPalette.surface
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: KinetixTheme.cornerRadiusControl)
                                    .stroke(
                                        isSelected
                                            ? KinetixPalette.accent
                                            : KinetixPalette.borderHairline,
                                        lineWidth: KinetixTheme.borderWidthHairline,
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func hitCard(hit: SearchHit) -> some View {
        Button {
            onSelectProduct(hit.sku)
        } label: {
            VStack(alignment: .leading, spacing: KinetixTheme.spacingXSmall) {
                HStack {
                    if let firstCategory = hit.categorySlugs.first {
                        Text(categoryDisplayNameProvider(firstCategory))
                            .font(KinetixTypography.caption)
                            .foregroundStyle(KinetixPalette.textTertiary)
                    }

                    Spacer(minLength: 0)

                    Text(hit.sku.value)
                        .font(KinetixTypography.labelMono)
                        .foregroundStyle(KinetixPalette.textMuted)
                }

                Text(hit.title)
                    .font(KinetixTypography.title)
                    .foregroundStyle(KinetixPalette.textPrimary)
                    .multilineTextAlignment(.leading)

                if let descriptionText = hit.descriptionText,
                    !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    Text(descriptionText)
                        .font(KinetixTypography.subheadline)
                        .foregroundStyle(KinetixPalette.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Text(
                    KinetixPriceFormatter.format(
                        amount: hit.indicativePriceMajor,
                        currency: hit.currency,
                        locale: locale,
                    )
                )
                .font(KinetixTypography.priceMono)
                .foregroundStyle(KinetixPalette.accentHigh)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
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

    private func sortLabel(for option: SearchSortOption) -> LocalizedStringResource {
        switch option {
        case .relevance:
            return .searchSortRelevance
        case .priceAscending:
            return .searchSortPriceAscending
        case .priceDescending:
            return .searchSortPriceDescending
        case .newest:
            return .searchSortNewest
        }
    }
}

#Preview {
    NavigationStack {
        SearchContent(
            queryText: "",
            suggestions: [],
            selectedCategorySlug: nil,
            selectedSort: .relevance,
            state: .empty,
            isLoadingMore: false,
            failureMapper: FailureMessageMapper(),
            categoryDisplayNameProvider: { $0.value },
            onQueryTextChanged: { _ in },
            onPickSuggestion: { _ in },
            onSelectCategoryFacet: { _ in },
            onSelectSort: { _ in },
            onSubmitSearch: {},
            onSelectProduct: { _ in },
            onLoadNextPage: { _ in },
        )
    }
    .preferredColorScheme(.dark)
}
