import Foundation

public enum OutboxOperationKind: String, Sendable, Equatable, Codable {
    case profileUpdate = "PROFILE_UPDATE"
}
