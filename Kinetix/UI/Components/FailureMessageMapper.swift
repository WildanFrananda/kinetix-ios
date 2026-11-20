import Foundation
import KinetixDomain

struct FailureMessageMapper {
    func message(for failure: Failure) -> LocalizedStringResource {
        switch failure {
        case .networkNotSent:
            return .errorNetworkNotSent
        case .outcomeUnknown:
            return .errorOutcomeUnknown
        case .serviceUnavailable:
            return .errorServiceUnavailable
        case .rateLimited(let rateLimit):
            if rateLimit.isSignInDelayed {
                return .errorSignInDelayed
            }

            return .errorRateLimited
        case .sessionExpired:
            return .errorSessionExpired
        case .unauthorized(let details):
            if details.code == "WRONG_CODE" {
                return .errorTwoFactorWrongCode
            }

            return .errorInvalidCredentials
        case .forbidden:
            return .errorForbidden
        case .notFound:
            return .errorNotFound
        case .conflict:
            return .errorConflict
        case .validation:
            return .errorValidation
        case .unprocessable:
            return .errorUnprocessable
        case .unsupportedAccountRole:
            return .errorUnsupportedRole
        case .sessionUnavailable:
            return .errorSessionUnavailable
        case .ledgerUnavailable:
            return .errorLedgerUnavailable
        case .unreadableResponse:
            return .errorUnreadableResponse
        case .server:
            return .errorServer
        case .cancelled:
            return .errorOutcomeUnknown
        }
    }
}
