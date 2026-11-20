import Foundation

public struct SuggestResponseDTO: Codable, Sendable {
    public let suggestions: [String]

    enum CodingKeys: String, CodingKey {
        case suggestions = "suggestions"
    }
}
