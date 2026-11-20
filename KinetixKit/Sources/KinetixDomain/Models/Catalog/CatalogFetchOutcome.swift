import Foundation

public enum CatalogFetchOutcome<Value: Equatable & Sendable>: Equatable, Sendable {
    case fresh(Value)
    case cachedStale(Value)

    public var value: Value {
        switch self {
        case .fresh(let val), .cachedStale(let val):
            return val
        }
    }

    public var isCachedStale: Bool {
        switch self {
        case .fresh:
            return false
        case .cachedStale:
            return true
        }
    }
}
