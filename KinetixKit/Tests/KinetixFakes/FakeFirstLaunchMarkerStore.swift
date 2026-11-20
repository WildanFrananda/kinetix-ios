import Foundation
import KinetixData
import Synchronization

public final class FakeFirstLaunchMarkerStore: FirstLaunchMarkerStore {
    private let completed: Mutex<Bool>

    public init(completed: Bool = false) {
        self.completed = Mutex(completed)
    }

    public func hasCompletedFirstLaunch() -> Bool {
        return completed.withLock { $0 }
    }

    public func markFirstLaunchCompleted() {
        completed.withLock { $0 = true }
    }
}
