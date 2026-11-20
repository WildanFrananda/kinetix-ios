import Foundation

public enum StoredSessionState: Sendable, Equatable {
    case signedOut
    case signedIn(AuthSession)
    case unreadable
}
