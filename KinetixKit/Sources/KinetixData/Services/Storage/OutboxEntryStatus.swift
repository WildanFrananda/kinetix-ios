import Foundation

public enum OutboxEntryStatus: String, Sendable, Equatable, Codable {
    case pending
    case inFlight
    case failed
}
