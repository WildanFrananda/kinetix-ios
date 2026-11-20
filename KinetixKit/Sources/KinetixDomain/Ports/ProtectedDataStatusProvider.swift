import Foundation

public protocol ProtectedDataStatusProvider: Sendable {
    func isProtectedDataAvailable() -> Bool
}
