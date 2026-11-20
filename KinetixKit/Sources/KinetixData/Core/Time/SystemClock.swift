import Foundation
import KinetixDomain

public struct SystemClock: AppClock {
    public init() {}

    public func now() -> Date {
        return Date()
    }

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
