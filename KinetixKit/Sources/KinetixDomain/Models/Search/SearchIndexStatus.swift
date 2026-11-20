import Foundation

public struct SearchIndexStatus: Equatable, Hashable, Codable, Sendable {
    public let indexedThroughMillis: Int64?
    public let ageSeconds: Int64?
    public let isStale: Bool

    public init(
        indexedThroughMillis: Int64?,
        ageSeconds: Int64?,
        isStale: Bool,
    ) {
        self.indexedThroughMillis = indexedThroughMillis
        self.ageSeconds = ageSeconds
        self.isStale = isStale
    }
}
