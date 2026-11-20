import Foundation
import KinetixDomain

nonisolated public enum CatalogHomeState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case empty
    case failed(Failure)
}
