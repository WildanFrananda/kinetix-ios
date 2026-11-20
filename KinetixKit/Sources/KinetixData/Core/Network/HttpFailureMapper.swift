import Foundation
import KinetixDomain

public struct HttpFailureMapper: Sendable {
    public static let defaultRateLimitWaitSeconds = 60

    private let errorParser: ApiErrorParser

    public init(errorParser: ApiErrorParser = ApiErrorParser()) {
        self.errorParser = errorParser
    }

    public func mapTransportError(_ error: HTTPTransportError) -> Failure {
        if error.isCancelled {
            return .cancelled
        }

        if error.requestLeftDevice || error.isTimedOut {
            return .outcomeUnknown
        }

        return .networkNotSent
    }

    public func mapResponse(
        _ response: HTTPResponse,
        isWrite: Bool,
        hasOwnUnauthorized: Bool,
    ) -> Failure {
        let envelope = errorParser.parse(response.body)

        switch response.statusCode {
        case 400:
            return .validation(
                ValidationFailure(
                    code: envelope.machineCode,
                    field: envelope.field,
                    messages: envelope.messages,
                )
            )
        case 401:
            if hasOwnUnauthorized {
                return .unauthorized(UnauthorizedFailure(code: envelope.machineCode))
            }

            return .sessionExpired
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(ConflictFailure(code: envelope.machineCode))
        case 422:
            return .unprocessable(
                UnprocessableFailure(
                    code: envelope.machineCode,
                    messages: envelope.messages,
                )
            )
        case 429:
            let isSignInDelayed = envelope.machineCode == "SIGN_IN_DELAYED"
            let waitSeconds = resolveRateLimitWaitSeconds(
                response: response,
                envelope: envelope,
            )
            return .rateLimited(
                RateLimitFailure(
                    retryAfterSeconds: waitSeconds,
                    isSignInDelayed: isSignInDelayed,
                )
            )
        case 502, 503, 504:
            if !envelope.isServiceJSON {
                return isWrite ? .outcomeUnknown : .serviceUnavailable
            }

            if response.statusCode == 503 {
                return .serviceUnavailable
            }

            return .server(
                ServerFailure(
                    statusCode: response.statusCode,
                    code: envelope.machineCode,
                    requestId: envelope.traceId ?? response.requestId,
                )
            )
        default:
            return .server(
                ServerFailure(
                    statusCode: response.statusCode,
                    code: envelope.machineCode,
                    requestId: envelope.traceId ?? response.requestId,
                )
            )
        }
    }

    private func resolveRateLimitWaitSeconds(
        response: HTTPResponse,
        envelope: ApiErrorEnvelope,
    ) -> Int {
        if let bodySeconds = envelope.retryAfterSeconds, bodySeconds > 0 {
            return bodySeconds
        }

        if let retryAfterHeader = response.headerValue(named: "Retry-After"),
            let parsed = parsePositiveInt(retryAfterHeader)
        {
            return parsed
        }

        if let resetHeader = response.headerValue(named: "x-ratelimit-reset"),
            let parsed = parsePositiveInt(resetHeader)
        {
            return parsed
        }

        return Self.defaultRateLimitWaitSeconds
    }

    private func parsePositiveInt(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value > 0 else {
            return nil
        }

        return value
    }
}
