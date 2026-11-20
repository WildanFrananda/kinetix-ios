import Foundation
import KinetixDomain
import Synchronization

public final class FakeAnalyticsTracker: AnalyticsTracker {
    private let state = Mutex<
        (principalId: PrincipalId?, events: [(name: String, params: [String: String])])
    >((principalId: nil, events: []))

    public init() {}

    public func setUserPrincipal(_ principalId: PrincipalId?) {
        state.withLock { $0.principalId = principalId }
    }

    public func logEvent(
        name: String,
        params: [String: String],
    ) {
        state.withLock { $0.events.append((name: name, params: params)) }
    }

    public func eventNames() -> [String] {
        return state.withLock { $0.events.map(\.name) }
    }

    public func currentPrincipal() -> PrincipalId? {
        return state.withLock { $0.principalId }
    }
}
