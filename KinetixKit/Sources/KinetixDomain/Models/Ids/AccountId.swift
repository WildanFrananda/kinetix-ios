import Foundation

public struct AccountId: Sendable, Equatable, Hashable, Codable {
    public let value: Int

    public init?(_ value: Int) {
        guard value >= 1 && value <= Int(Int32.max) else {
            return nil
        }

        self.value = value
    }
}
