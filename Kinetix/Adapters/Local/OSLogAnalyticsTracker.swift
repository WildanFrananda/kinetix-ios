import Foundation
import KinetixDomain
import OSLog

struct OSLogAnalyticsTracker: AnalyticsTracker {
    private let logger = Logger(subsystem: "com.kinetix.shop", category: "analytics")

    func setUserPrincipal(_ principalId: PrincipalId?) {
        let state = principalId == nil ? "cleared" : "set"
        logger.info("analytics_principal state=\(state, privacy: .public)")
    }

    func logEvent(
        name: String,
        params: [String: String],
    ) {
        let keys = params.keys.sorted().joined(separator: ",")
        logger.info(
            "event name=\(name, privacy: .public) keys=\(keys, privacy: .public)"
        )
    }
}
