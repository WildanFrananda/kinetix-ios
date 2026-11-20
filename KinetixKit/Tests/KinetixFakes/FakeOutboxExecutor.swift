import Foundation
import KinetixData
import KinetixDomain
import Synchronization

public final class FakeOutboxExecutor: OutboxExecutor {
    private let state = Mutex<
        (
            results: [Result<Void, Failure>],
            executedKeys: [String],
        )
    >((results: [], executedKeys: []))

    public init(results: [Result<Void, Failure>] = []) {
        self.state.withLock { $0.results = results }
    }

    public func enqueue(_ result: Result<Void, Failure>) {
        state.withLock { $0.results.append(result) }
    }

    public func executedKeys() -> [String] {
        return state.withLock { $0.executedKeys }
    }

    public func execute(_ entry: OutboxEntrySnapshot) async -> Result<Void, Failure> {
        return state.withLock { current in
            current.executedKeys.append(entry.dedupeKey)
            guard !current.results.isEmpty else {
                return .success(())
            }

            return current.results.removeFirst()
        }
    }
}
