import Foundation
import KinetixDomain

nonisolated public enum ProfileSaveState: Sendable, Equatable {
    case idle
    case saving
    case savedConfirmed
    case savedLocallyPendingSync
    case failed(Failure)
}
