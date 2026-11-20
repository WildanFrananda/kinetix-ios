import Foundation

public struct PrincipalId: Sendable, Equatable, Hashable, Codable {
    public let value: String

    public init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard UUID(uuidString: trimmed) != nil else {
            return nil
        }

        self.value = trimmed.lowercased()
    }
}
