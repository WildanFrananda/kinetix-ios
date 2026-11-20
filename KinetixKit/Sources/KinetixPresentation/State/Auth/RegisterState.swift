import Foundation
import KinetixDomain

nonisolated public enum RegisterState: Sendable, Equatable {
    case idle
    case submitting
    case rateLimited(secondsRemaining: Int)
    case failed(Failure)
    case registered(AuthSession)
}
