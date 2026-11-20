import Foundation

public actor InFlightReadCoalescer<Key: Hashable & Sendable, Value: Sendable> {
    private var waitersByKey: [Key: [CheckedContinuation<Value, Never>]] = [:]

    public init() {}

    public func coalesce(
        key: Key,
        operation: @Sendable () async -> Value,
    ) async -> Value {
        if waitersByKey[key] != nil {
            return await withCheckedContinuation { continuation in
                waitersByKey[key, default: []].append(continuation)
            }
        }

        waitersByKey[key] = []
        let result = await operation()
        let continuations = waitersByKey.removeValue(forKey: key) ?? []
        for continuation in continuations {
            continuation.resume(returning: result)
        }

        return result
    }
}
