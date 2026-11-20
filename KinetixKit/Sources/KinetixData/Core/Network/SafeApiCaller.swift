import Foundation
import KinetixDomain

public struct SafeApiCaller: Sendable {
    private let transport: any HTTPTransport
    private let sessionRenewer: SessionRenewer
    private let failureMapper: HttpFailureMapper

    public init(
        transport: any HTTPTransport,
        sessionRenewer: SessionRenewer,
        failureMapper: HttpFailureMapper = HttpFailureMapper(),
    ) {
        self.transport = transport
        self.sessionRenewer = sessionRenewer
        self.failureMapper = failureMapper
    }

    public func execute(_ request: HTTPRequest) async -> Result<HTTPResponse, Failure> {
        if !request.requiresAuth {
            return await sendOnce(request)
        }

        let sessionResult = await sessionRenewer.validAccessSession()
        let activeSession: AuthSession
        switch sessionResult {
        case .success(let session):
            activeSession = session
        case .failure(let failure):
            return .failure(failure)
        }

        let authorizedRequest = attachBearer(to: request, token: activeSession.accessToken)
        let firstAttempt = await sendRaw(authorizedRequest)

        switch firstAttempt {
        case .failure(let error):
            return .failure(failureMapper.mapTransportError(error))
        case .success(let response):
            if response.statusCode == 401 && !request.hasOwnUnauthorized {
                let renewedResult = await sessionRenewer.validAccessSession(forceRefresh: true)
                switch renewedResult {
                case .failure(let failure):
                    return .failure(failure)
                case .success(let renewedSession):
                    let retryRequest = attachBearer(
                        to: request,
                        token: renewedSession.accessToken,
                    )
                    return await sendOnce(retryRequest)
                }
            }

            if (200...299).contains(response.statusCode) {
                return .success(response)
            }

            return .failure(
                failureMapper.mapResponse(
                    response,
                    isWrite: request.isWrite,
                    hasOwnUnauthorized: request.hasOwnUnauthorized,
                )
            )
        }
    }

    private func sendOnce(_ request: HTTPRequest) async -> Result<HTTPResponse, Failure> {
        let rawResult = await sendRaw(request)
        switch rawResult {
        case .failure(let error):
            return .failure(failureMapper.mapTransportError(error))
        case .success(let response):
            if (200...299).contains(response.statusCode) {
                return .success(response)
            }

            return .failure(
                failureMapper.mapResponse(
                    response,
                    isWrite: request.isWrite,
                    hasOwnUnauthorized: request.hasOwnUnauthorized,
                )
            )
        }
    }

    private func sendRaw(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPTransportError> {
        return await transport.send(request)
    }

    private func attachBearer(
        to request: HTTPRequest,
        token: String,
    ) -> HTTPRequest {
        var headers = request.headers
        headers["Authorization"] = "Bearer \(token)"
        return HTTPRequest(
            method: request.method,
            path: request.path,
            headers: headers,
            body: request.body,
            isWrite: request.isWrite,
            hasOwnUnauthorized: request.hasOwnUnauthorized,
            requiresAuth: request.requiresAuth,
            timeoutSeconds: request.timeoutSeconds,
        )
    }
}
