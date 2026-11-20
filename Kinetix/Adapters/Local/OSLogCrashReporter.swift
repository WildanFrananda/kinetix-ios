import Foundation
import KinetixDomain
import OSLog

struct OSLogCrashReporter: CrashReporter {
    private let logger = Logger(subsystem: "com.kinetix.shop", category: "crash")

    func setUserPrincipal(_ principalId: PrincipalId?) {
        let state = principalId == nil ? "cleared" : "set"
        logger.info("crash_principal state=\(state, privacy: .public)")
    }

    func recordNonFatal(
        code: String,
        context: [String: String],
    ) {
        let keys = context.keys.sorted().joined(separator: ",")
        logger.error(
            "non_fatal code=\(code, privacy: .public) keys=\(keys, privacy: .public)"
        )
    }
}
