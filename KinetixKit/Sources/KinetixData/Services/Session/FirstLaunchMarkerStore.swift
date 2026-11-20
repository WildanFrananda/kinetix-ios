import Foundation

public protocol FirstLaunchMarkerStore: Sendable {
    func hasCompletedFirstLaunch() -> Bool
    func markFirstLaunchCompleted()
}
