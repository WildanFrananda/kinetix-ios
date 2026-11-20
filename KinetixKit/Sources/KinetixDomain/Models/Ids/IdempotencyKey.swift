import Foundation

public struct IdempotencyKey: Sendable, Equatable, Hashable, Codable {
    public let value: String

    public init?(_ rawValue: String) {
        guard !rawValue.isEmpty && rawValue.count <= 100 else {
            return nil
        }

        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:-"
        )
        guard rawValue.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return nil
        }

        self.value = rawValue
    }

    public static func generate() -> IdempotencyKey {
        let raw = UUID().uuidString.lowercased()
        return IdempotencyKey(unchecked: raw)
    }

    private init(unchecked value: String) {
        self.value = value
    }
}
