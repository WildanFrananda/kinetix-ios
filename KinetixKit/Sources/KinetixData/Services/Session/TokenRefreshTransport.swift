import Foundation
import KinetixDomain

public struct TokenRefreshTransport: Sendable {
    private let transport: any HTTPTransport
    private let clock: any AppClock
    private let errorParser: ApiErrorParser
    private let failureMapper: HttpFailureMapper

    public init(
        transport: any HTTPTransport,
        clock: any AppClock,
        errorParser: ApiErrorParser = ApiErrorParser(),
        failureMapper: HttpFailureMapper = HttpFailureMapper(),
    ) {
        self.transport = transport
        self.clock = clock
        self.errorParser = errorParser
        self.failureMapper = failureMapper
    }

    public func refresh(refreshToken: String) async -> RefreshTransportOutcome {
        guard let body = try? JSONEncoder().encode(RefreshRequestDTO(refreshToken: refreshToken))
        else {
            return .unknown
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/refresh",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: false,
        )

        let transportResult = await transport.send(request)
        switch transportResult {
        case .failure(let error):
            if error.isCancelled {
                return .notSpent(.cancelled)
            }

            if !error.requestLeftDevice && !error.isTimedOut {
                return .notSpent(.networkNotSent)
            }

            return .unknown
        case .success(let response):
            return classify(response: response)
        }
    }

    private func classify(response: HTTPResponse) -> RefreshTransportOutcome {
        switch response.statusCode {
        case 200:
            guard
                let dto = try? JSONDecoder().decode(
                    AuthSessionResponseDTO.self,
                    from: response.body,
                ),
                let session = dto.toDomain(issuedAt: clock.now())
            else {
                return .unknown
            }

            return .refreshed(session)
        case 400, 401, 403:
            return .refused
        case 429:
            let failure = failureMapper.mapResponse(
                response,
                isWrite: true,
                hasOwnUnauthorized: true,
            )
            return .notSpent(failure)
        case 502, 503:
            let envelope = errorParser.parse(response.body)
            if !envelope.isServiceJSON {
                return .notSpent(.serviceUnavailable)
            }

            if response.statusCode == 503 && envelope.machineCode == "DATABASE_UNAVAILABLE" {
                return .notSpent(.serviceUnavailable)
            }

            return .unknown
        default:
            return .unknown
        }
    }
}
