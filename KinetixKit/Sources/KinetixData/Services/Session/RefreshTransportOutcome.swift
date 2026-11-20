import Foundation
import KinetixDomain

public enum RefreshTransportOutcome: Sendable, Equatable {
    case refreshed(AuthSession)
    case refused
    case notSpent(Failure)
    case unknown
}
