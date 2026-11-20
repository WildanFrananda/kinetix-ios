import Foundation

public enum AvatarUpdate: Sendable, Equatable, Codable {
    case unchanged
    case set(String)
    case remove
}
