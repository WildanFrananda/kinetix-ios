import Foundation
import KinetixDomain
import OSLog

public final class URLSessionHTTPTransport: HTTPTransport {
    private let baseURL: URL
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kinetix.shop", category: "http")

    public init(
        baseURL: URL,
        configuration: URLSessionConfiguration =
            URLSessionHTTPTransport.makeEphemeralConfiguration(),
    ) {
        self.baseURL = baseURL
        self.session = URLSession(configuration: configuration)
    }

    public static func makeEphemeralConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        return configuration
    }

    public func buildURLRequest(
        from request: HTTPRequest,
        requestId: String,
    ) -> URLRequest? {
        guard let url = URL(string: request.path, relativeTo: baseURL)?.absoluteURL else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.httpShouldHandleCookies = false
        if let timeoutSeconds = request.timeoutSeconds {
            urlRequest.timeoutInterval = timeoutSeconds
        }

        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-Id")

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.httpBody = body
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } else {
            urlRequest.setValue(nil, forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }

    public func send(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPTransportError> {
        let requestId = UUID().uuidString.lowercased()
        guard let urlRequest = buildURLRequest(from: request, requestId: requestId) else {
            return .failure(
                HTTPTransportError(
                    underlyingError: URLError(.badURL),
                    requestLeftDevice: false,
                    isCancelled: false,
                    isTimedOut: false,
                    requestId: requestId,
                )
            )
        }

        let delegate = URLSessionTaskMetricsDelegate()

        do {
            let (data, rawResponse) = try await session.data(for: urlRequest, delegate: delegate)
            guard let httpResponse = rawResponse as? HTTPURLResponse else {
                return .failure(
                    HTTPTransportError(
                        underlyingError: URLError(.badServerResponse),
                        requestLeftDevice: delegate.resolvedRequestLeftDevice(),
                        isCancelled: false,
                        isTimedOut: false,
                        requestId: requestId,
                    )
                )
            }

            var headers: [String: String] = [:]
            for (rawKey, rawValue) in httpResponse.allHeaderFields {
                if let key = rawKey as? String, let value = rawValue as? String {
                    headers[key] = value
                }
            }

            let method = request.method.rawValue
            let status = httpResponse.statusCode
            logger.info(
                "http method=\(method, privacy: .public) status=\(status, privacy: .public) id=\(requestId, privacy: .public)"
            )

            return .success(
                HTTPResponse(
                    statusCode: httpResponse.statusCode,
                    headers: headers,
                    body: data,
                    requestId: requestId,
                    requestLeftDevice: delegate.resolvedRequestLeftDevice(),
                )
            )
        } catch is CancellationError {
            return .failure(
                HTTPTransportError(
                    underlyingError: CancellationError(),
                    requestLeftDevice: delegate.resolvedRequestLeftDevice(),
                    isCancelled: true,
                    isTimedOut: false,
                    requestId: requestId,
                )
            )
        } catch let urlError as URLError {
            let isCancelled = urlError.code == .cancelled
            let isTimedOut = urlError.code == .timedOut
            let leftDevice = delegate.resolvedRequestLeftDevice()

            let method = request.method.rawValue
            let code = urlError.errorCode
            logger.warning(
                "http_error method=\(method, privacy: .public) code=\(code, privacy: .public) left=\(leftDevice, privacy: .public) id=\(requestId, privacy: .public)"
            )

            return .failure(
                HTTPTransportError(
                    underlyingError: urlError,
                    requestLeftDevice: leftDevice,
                    isCancelled: isCancelled,
                    isTimedOut: isTimedOut,
                    requestId: requestId,
                )
            )
        } catch {
            return .failure(
                HTTPTransportError(
                    underlyingError: error,
                    requestLeftDevice: delegate.resolvedRequestLeftDevice(),
                    isCancelled: false,
                    isTimedOut: false,
                    requestId: requestId,
                )
            )
        }
    }
}
