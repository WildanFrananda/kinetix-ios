import Foundation
import KinetixDomain

nonisolated public enum SearchScreenState: Equatable, Sendable {
    case idle
    case searching
    case results(SearchResponse)
    case empty
    case failed(Failure)
}
