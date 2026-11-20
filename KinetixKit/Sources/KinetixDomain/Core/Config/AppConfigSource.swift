import Foundation

public protocol AppConfigSource: Sendable {
    func readRawConfig() -> AppConfigInput
}
