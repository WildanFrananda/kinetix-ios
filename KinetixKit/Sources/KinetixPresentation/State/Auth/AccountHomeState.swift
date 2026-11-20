import Foundation

nonisolated public enum AccountHomeState: Sendable, Equatable {
    case idle
    case signingOut
    case signedOut
}
