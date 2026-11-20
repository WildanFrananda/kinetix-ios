import Foundation

public protocol AnalyticsTracker: Sendable {
    func setUserPrincipal(_ principalId: PrincipalId?)
    func logEvent(
        name: String,
        params: [String: String],
    )
}
