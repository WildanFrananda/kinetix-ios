import Foundation
import KinetixDomain
import Synchronization

public final class FakeCrashReporter: CrashReporter {
    private let state = Mutex<
        (principalId: PrincipalId?, events: [(code: String, context: [String: String])])
    >((principalId: nil, events: []))

    public init() {}

    public func setUserPrincipal(_ principalId: PrincipalId?) {
        state.withLock { $0.principalId = principalId }
    }

    public func recordNonFatal(
        code: String,
        context: [String: String],
    ) {
        state.withLock { $0.events.append((code: code, context: context)) }
    }

    public func recordedCodes() -> [String] {
        return state.withLock { $0.events.map(\.code) }
    }

    public func currentPrincipal() -> PrincipalId? {
        return state.withLock { $0.principalId }
    }
}
