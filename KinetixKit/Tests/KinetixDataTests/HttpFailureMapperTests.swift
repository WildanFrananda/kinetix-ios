import Foundation
import KinetixData
import KinetixDomain
import Testing

struct HttpFailureMapperTests {
    private let mapper = HttpFailureMapper()

    @Test
    func pinsEphemeralURLSessionConfigurationAndEmptyBodyHeaders() throws {
        let config = URLSessionHTTPTransport.makeEphemeralConfiguration()
        #expect(config.urlCache == nil)
        #expect(config.requestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(config.httpCookieStorage == nil)
        #expect(config.httpShouldSetCookies == false)
        #expect(config.urlCredentialStorage == nil)

        let base = try #require(URL(string: "https://api.example.test"))
        let transport = URLSessionHTTPTransport(baseURL: base, configuration: config)
        let getRequest = try #require(
            transport.buildURLRequest(
                from: HTTPRequest(method: .get, path: "/api/v1/auth/me"),
                requestId: "req-1",
            )
        )
        #expect(getRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(getRequest.value(forHTTPHeaderField: "X-Request-Id") == "req-1")
        #expect(getRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test
    func classifiesGatewayPlainText503AsUnknownOnWriteAndUnavailableOnRead() {
        let gatewayResponse = HTTPResponse(
            statusCode: 503,
            headers: [:],
            body: Data("upstream connect error".utf8),
            requestId: "req-503",
        )

        #expect(
            mapper.mapResponse(gatewayResponse, isWrite: true, hasOwnUnauthorized: false)
                == .outcomeUnknown
        )
        #expect(
            mapper.mapResponse(gatewayResponse, isWrite: false, hasOwnUnauthorized: false)
                == .serviceUnavailable
        )
    }

    @Test
    func resolves429WaitPrecedenceAndSignInDelayedFlag() {
        let delayedBody = Data(
            #"{"error":"SIGN_IN_DELAYED","retryAfterSeconds":8,"message":"wait"}"#.utf8
        )
        let delayed = HTTPResponse(
            statusCode: 429,
            headers: ["Retry-After": "12"],
            body: delayedBody,
            requestId: "req-delay",
        )
        #expect(
            mapper.mapResponse(delayed, isWrite: true, hasOwnUnauthorized: true)
                == .rateLimited(RateLimitFailure(retryAfterSeconds: 8, isSignInDelayed: true))
        )

        let gateway429 = HTTPResponse(
            statusCode: 429,
            headers: [:],
            body: Data("local_rate_limited".utf8),
            requestId: "req-gw-429",
        )
        #expect(
            mapper.mapResponse(gateway429, isWrite: false, hasOwnUnauthorized: false)
                == .rateLimited(
                    RateLimitFailure(
                        retryAfterSeconds: HttpFailureMapper.defaultRateLimitWaitSeconds,
                        isSignInDelayed: false,
                    )
                )
        )

        let resetHeader429 = HTTPResponse(
            statusCode: 429,
            headers: ["x-ratelimit-reset": "23"],
            body: Data(),
            requestId: "req-reset",
        )
        #expect(
            mapper.mapResponse(resetHeader429, isWrite: false, hasOwnUnauthorized: false)
                == .rateLimited(RateLimitFailure(retryAfterSeconds: 23, isSignInDelayed: false))
        )
    }

    @Test
    func classifiesTransportErrorsByWhetherRequestLeftDevice() {
        let notSent = HTTPTransportError(
            underlyingError: URLError(.notConnectedToInternet),
            requestLeftDevice: false,
            isCancelled: false,
            isTimedOut: false,
            requestId: "req-offline",
        )
        #expect(mapper.mapTransportError(notSent) == .networkNotSent)

        let timedOutAfterSend = HTTPTransportError(
            underlyingError: URLError(.timedOut),
            requestLeftDevice: true,
            isCancelled: false,
            isTimedOut: true,
            requestId: "req-timeout",
        )
        #expect(mapper.mapTransportError(timedOutAfterSend) == .outcomeUnknown)

        let cancelled = HTTPTransportError(
            underlyingError: CancellationError(),
            requestLeftDevice: false,
            isCancelled: true,
            isTimedOut: false,
            requestId: "req-cancel",
        )
        #expect(mapper.mapTransportError(cancelled) == .cancelled)
    }
}
