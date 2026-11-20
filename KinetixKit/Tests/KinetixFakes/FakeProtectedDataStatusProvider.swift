import Foundation
import KinetixDomain
import Synchronization

public final class FakeProtectedDataStatusProvider: ProtectedDataStatusProvider {
    private let available: Mutex<Bool>

    public init(available: Bool = true) {
        self.available = Mutex(available)
    }

    public func isProtectedDataAvailable() -> Bool {
        return available.withLock { $0 }
    }

    public func setAvailable(_ value: Bool) {
        available.withLock { $0 = value }
    }
}
