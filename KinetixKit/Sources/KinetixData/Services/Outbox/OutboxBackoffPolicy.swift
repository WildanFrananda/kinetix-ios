import Foundation
import KinetixDomain

public struct OutboxBackoffPolicy: Sendable {
    public static let initialDelaySeconds = 15
    public static let maxDelaySeconds = 300

    public static func delaySeconds(
        forAttempt attempt: Int,
        failure: Failure,
    ) -> Int {
        if case .rateLimited(let rateLimit) = failure, rateLimit.retryAfterSeconds > 0 {
            return rateLimit.retryAfterSeconds
        }

        let clampedAttempt = max(1, min(attempt, 10))
        let exponent = clampedAttempt - 1
        let computed = initialDelaySeconds * (1 << exponent)
        return min(computed, maxDelaySeconds)
    }

    public static func isRetryable(
        failure: Failure,
        operationKind: OutboxOperationKind,
    ) -> Bool {
        switch failure {
        case .networkNotSent, .outcomeUnknown, .serviceUnavailable, .rateLimited, .sessionExpired,
            .sessionUnavailable, .server:
            return true
        case .conflict:
            return operationKind == .profileUpdate
        case .validation, .unprocessable, .unauthorized, .forbidden, .notFound,
            .unsupportedAccountRole, .ledgerUnavailable, .unreadableResponse, .cancelled:
            return false
        }
    }
}
