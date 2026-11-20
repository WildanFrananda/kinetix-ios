import Foundation
import KinetixDomain

public struct SearchIndexDTO: Codable, Sendable {
    public let indexedThroughMillis: Int64?
    public let ageSeconds: Int64?
    public let stale: Bool

    enum CodingKeys: String, CodingKey {
        case indexedThroughMillis = "indexed_through_ms"
        case ageSeconds = "age_seconds"
        case stale = "stale"
    }

    public func toDomain() -> SearchIndexStatus {
        return SearchIndexStatus(
            indexedThroughMillis: indexedThroughMillis,
            ageSeconds: ageSeconds,
            isStale: stale,
        )
    }
}
