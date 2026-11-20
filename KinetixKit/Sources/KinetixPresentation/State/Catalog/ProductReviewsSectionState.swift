import Foundation
import KinetixDomain

nonisolated public enum ProductReviewsSectionState: Equatable, Sendable {
    case loading
    case loaded(ReviewPage)
    case failed(Failure)
}
