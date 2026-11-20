import Foundation
import KinetixDomain
import Testing

@testable import Kinetix

struct FailureMessageMapperTests {
    @Test
    @MainActor
    func mapsEveryFailureCaseToNonEmptyLocalizedMessage() {
        let mapper = FailureMessageMapper()
        let cases: [Failure] = [
            .networkNotSent,
            .outcomeUnknown,
            .serviceUnavailable,
            .rateLimited(RateLimitFailure(retryAfterSeconds: 10, isSignInDelayed: false)),
            .rateLimited(RateLimitFailure(retryAfterSeconds: 8, isSignInDelayed: true)),
            .sessionExpired,
            .unauthorized(UnauthorizedFailure(code: "WRONG_CODE")),
            .unauthorized(UnauthorizedFailure(code: nil)),
            .forbidden,
            .notFound,
            .conflict(ConflictFailure()),
            .validation(ValidationFailure()),
            .unprocessable(UnprocessableFailure()),
            .unsupportedAccountRole,
            .sessionUnavailable,
            .ledgerUnavailable,
            .unreadableResponse,
            .server(ServerFailure(statusCode: 500)),
            .cancelled,
        ]

        for failure in cases {
            let text = String(localized: mapper.message(for: failure))
            #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
