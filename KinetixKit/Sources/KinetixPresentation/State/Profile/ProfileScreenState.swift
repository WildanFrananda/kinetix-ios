import Foundation
import KinetixDomain

nonisolated public enum ProfileScreenState: Sendable, Equatable {
    case idle
    case loading
    case notCreated
    case loaded(DeliveryProfile)
    case cachedStale(DeliveryProfile)
    case pendingLocalSync(DeliveryProfile)
    case failed(Failure)
}
