import Foundation

public protocol RoutePersistenceStore: Sendable {
    func loadEncodedPath(for principalId: PrincipalId) -> Data?
    func saveEncodedPath(
        _ data: Data,
        for principalId: PrincipalId,
    )
    func clearPath(for principalId: PrincipalId)
}
