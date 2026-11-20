import Foundation
import KinetixData
import KinetixDomain
import Synchronization

public final class FakeSessionVault: SessionVault {
    private let state:
        Mutex<
            (
                stored: StoredSessionState,
                writeCount: Int,
                clearCount: Int,
                failNextWrite: Bool,
            )
        >

    public init(initial: StoredSessionState = .signedOut) {
        self.state = Mutex(
            (stored: initial, writeCount: 0, clearCount: 0, failNextWrite: false)
        )
    }

    public func read() -> StoredSessionState {
        return state.withLock { $0.stored }
    }

    public func write(_ session: AuthSession) -> Result<Void, Failure> {
        return state.withLock { current in
            if current.failNextWrite {
                current.failNextWrite = false
                return .failure(.sessionUnavailable)
            }

            current.stored = .signedIn(session)
            current.writeCount += 1
            return .success(())
        }
    }

    public func clear() -> Result<Void, Failure> {
        return state.withLock { current in
            current.stored = .signedOut
            current.clearCount += 1
            return .success(())
        }
    }

    public func setStored(_ next: StoredSessionState) {
        state.withLock { $0.stored = next }
    }

    public func writeCount() -> Int {
        return state.withLock { $0.writeCount }
    }

    public func clearCount() -> Int {
        return state.withLock { $0.clearCount }
    }
}
