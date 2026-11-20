import Foundation

public enum Failure: Error, Sendable, Equatable, Hashable {
    case networkNotSent
    case outcomeUnknown
    case serviceUnavailable
    case rateLimited(RateLimitFailure)
    case sessionExpired
    case unauthorized(UnauthorizedFailure)
    case forbidden
    case notFound
    case conflict(ConflictFailure)
    case validation(ValidationFailure)
    case unprocessable(UnprocessableFailure)
    case unsupportedAccountRole
    case sessionUnavailable
    case ledgerUnavailable
    case unreadableResponse
    case server(ServerFailure)
    case cancelled
}
