import Foundation

public enum ProfileFetchOutcome: Sendable, Equatable {
    case notCreated
    case confirmed(DeliveryProfile)
    case cachedStale(DeliveryProfile)
    case pendingLocalSync(DeliveryProfile)
}
