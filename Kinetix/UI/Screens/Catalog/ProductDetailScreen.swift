import KinetixDomain
import KinetixPresentation
import SwiftUI

struct ProductDetailScreen: View {
    @State private var viewModel: ProductDetailViewModel

    private let failureMapper: FailureMessageMapper
    private let imagePipeline: ImagePipeline

    init(
        viewModel: ProductDetailViewModel,
        failureMapper: FailureMessageMapper,
        imagePipeline: ImagePipeline,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.failureMapper = failureMapper
        self.imagePipeline = imagePipeline
    }

    var body: some View {
        ProductDetailContent(
            state: viewModel.state,
            productReviewsState: viewModel.productReviewsState,
            merchantReviewsState: viewModel.merchantReviewsState,
            isLoadingMoreProductReviews: viewModel.isLoadingMoreProductReviews,
            isLoadingMoreMerchantReviews: viewModel.isLoadingMoreMerchantReviews,
            failureMapper: failureMapper,
            imagePipeline: imagePipeline,
            onLoadMoreProductReviews: viewModel.loadMoreProductReviews,
            onLoadMoreMerchantReviews: viewModel.loadMoreMerchantReviews,
            onRefresh: viewModel.refresh,
        )
        .task {
            viewModel.start()
        }
    }
}
