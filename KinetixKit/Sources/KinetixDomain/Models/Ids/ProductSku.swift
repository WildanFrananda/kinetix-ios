import Foundation

public struct ProductSku: Hashable, Codable, Sendable {
    public let value: String

    public init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 128 else {
            return nil
        }

        self.value = trimmed
    }
}
