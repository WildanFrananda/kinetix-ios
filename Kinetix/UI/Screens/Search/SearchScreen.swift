import KinetixDomain
import KinetixPresentation
import SwiftUI

struct SearchScreen: View {
    @State private var viewModel: SearchViewModel

    private let failureMapper: FailureMessageMapper
    private let onSelectProduct: (ProductSku) -> Void

    init(
        viewModel: SearchViewModel,
        failureMapper: FailureMessageMapper,
        onSelectProduct: @escaping (ProductSku) -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
        self.onSelectProduct = onSelectProduct
    }

    var body: some View {
        SearchContent(
            queryText: viewModel.queryText,
            suggestions: viewModel.suggestions,
            selectedCategorySlug: viewModel.selectedCategorySlug,
            selectedSort: viewModel.selectedSort,
            state: viewModel.state,
            isLoadingMore: viewModel.isLoadingMore,
            failureMapper: failureMapper,
            categoryDisplayNameProvider: { slug in
                viewModel.categoryDisplayName(for: slug)
            },
            onQueryTextChanged: { text in
                viewModel.onQueryTextChanged(text)
            },
            onPickSuggestion: { suggestion in
                viewModel.pickSuggestion(suggestion)
            },
            onSelectCategoryFacet: { slug in
                viewModel.selectCategoryFacet(slug)
            },
            onSelectSort: { sort in
                viewModel.selectSort(sort)
            },
            onSubmitSearch: viewModel.submitSearch,
            onSelectProduct: onSelectProduct,
            onLoadNextPage: { sku in
                viewModel.loadNextPageIfNeeded(currentSku: sku)
            },
        )
        .task {
            viewModel.start()
        }
    }
}
