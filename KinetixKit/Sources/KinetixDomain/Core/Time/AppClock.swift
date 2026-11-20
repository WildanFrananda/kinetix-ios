import Foundation

public protocol AppClock: Sendable {
    func now() -> Date
    func sleep(for duration: Duration) async throws
}
