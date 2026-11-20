import KinetixDomain
import KinetixPresentation
import SwiftUI

struct CatalogHomeScreen: View {
    @State private var viewModel: CatalogHomeViewModel

    private let isAuthenticated: Bool
    private let failureMapper: FailureMessageMapper
    private let imagePipeline: ImagePipeline
    private let onOpenSearch: () -> Void
    private let onOpenLanguageSettings: () -> Void
    private let onOpenAccountOrSignIn: () -> Void
    private let onSelectProduct: (ProductSku) -> Void

    init(
        viewModel: CatalogHomeViewModel,
        isAuthenticated: Bool,
        failureMapper: FailureMessageMapper,
        imagePipeline: ImagePipeline,
        onOpenSearch: @escaping () -> Void,
        onOpenLanguageSettings: @escaping () -> Void,
        onOpenAccountOrSignIn: @escaping () -> Void,
        onSelectProduct: @escaping (ProductSku) -> Void,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.isAuthenticated = isAuthenticated
        self.failureMapper = failureMapper
        self.imagePipeline = imagePipeline
        self.onOpenSearch = onOpenSearch
        self.onOpenLanguageSettings = onOpenLanguageSettings
        self.onOpenAccountOrSignIn = onOpenAccountOrSignIn
        self.onSelectProduct = onSelectProduct
    }

    var body: some View {
        CatalogHomeContent(
            state: viewModel.state,
            categories: viewModel.categories,
            selectedCategorySlug: viewModel.selectedCategorySlug,
            products: viewModel.products,
            isShowingCachedStale: viewModel.isShowingCachedStale,
            isLoadingNextPage: viewModel.isLoadingNextPage,
            paginationFailure: viewModel.paginationFailure,
            isAuthenticated: isAuthenticated,
            failureMapper: failureMapper,
            imagePipeline: imagePipeline,
            priceIndicationProvider: { product in
                viewModel.priceIndication(for: product)
            },
            onSelectCategory: { slug in
                viewModel.selectCategory(slug)
            },
            onOpenSearch: onOpenSearch,
            onOpenLanguageSettings: onOpenLanguageSettings,
            onOpenAccountOrSignIn: onOpenAccountOrSignIn,
            onSelectProduct: onSelectProduct,
            onLoadNextPage: { sku in
                viewModel.loadNextPageIfNeeded(currentSku: sku)
            },
            onRetryNextPage: {
                viewModel.loadNextPageIfNeeded()
            },
            onRefresh: viewModel.refresh,
        )
        .task {
            viewModel.start()
        }
    }
}
