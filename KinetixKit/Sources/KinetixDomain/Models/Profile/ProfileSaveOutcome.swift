import Foundation

public enum ProfileSaveOutcome: Sendable, Equatable {
    case confirmed(DeliveryProfile)
    case queuedOffline(DeliveryProfile)
}
