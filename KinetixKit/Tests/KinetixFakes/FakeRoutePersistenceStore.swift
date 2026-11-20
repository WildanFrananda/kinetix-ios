import Foundation
import KinetixDomain
import Synchronization

public final class FakeRoutePersistenceStore: RoutePersistenceStore {
    private let paths = Mutex<[PrincipalId: Data]>([:])

    public init() {}

    public func loadEncodedPath(for principalId: PrincipalId) -> Data? {
        return paths.withLock { $0[principalId] }
    }

    public func saveEncodedPath(
        _ data: Data,
        for principalId: PrincipalId,
    ) {
        paths.withLock { $0[principalId] = data }
    }

    public func clearPath(for principalId: PrincipalId) {
        paths.withLock { $0[principalId] = nil }
    }
}
