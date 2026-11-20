import Foundation
import KinetixDomain
import Synchronization

public final class FakeAppClock: AppClock {
    private let state: Mutex<(now: Date, sleptDurations: [Duration])>

    public init(now: Date = Date(timeIntervalSince1970: 1_760_000_000)) {
        self.state = Mutex((now: now, sleptDurations: []))
    }

    public func now() -> Date {
        return state.withLock { $0.now }
    }

    public func advance(by seconds: TimeInterval) {
        state.withLock { current in
            current.now = current.now.addingTimeInterval(seconds)
        }
    }

    public func sleptDurations() -> [Duration] {
        return state.withLock { $0.sleptDurations }
    }

    public func sleep(for duration: Duration) async throws {
        try Task.checkCancellation()
        state.withLock { current in
            current.sleptDurations.append(duration)
            let seconds = Double(duration.components.seconds)
            current.now = current.now.addingTimeInterval(seconds)
        }
    }
}
