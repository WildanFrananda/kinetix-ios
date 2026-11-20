import Foundation
import KinetixData
import Synchronization

public final class FakeHTTPTransport: HTTPTransport {
    private let state = Mutex<
        (
            queue: [Result<HTTPResponse, HTTPTransportError>],
            sent: [HTTPRequest],
            delayNanoseconds: UInt64,
        )
    >((queue: [], sent: [], delayNanoseconds: 0))

    public init(
        responses: [Result<HTTPResponse, HTTPTransportError>] = [],
        delayNanoseconds: UInt64 = 0,
    ) {
        self.state.withLock { current in
            current.queue = responses
            current.delayNanoseconds = delayNanoseconds
        }
    }

    public func enqueue(_ result: Result<HTTPResponse, HTTPTransportError>) {
        state.withLock { $0.queue.append(result) }
    }

    public func sentRequests() -> [HTTPRequest] {
        return state.withLock { $0.sent }
    }

    public func send(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPTransportError> {
        let delay = state.withLock { current -> UInt64 in
            current.sent.append(request)
            return current.delayNanoseconds
        }

        if delay > 0 {
            try? await Task.sleep(nanoseconds: delay)
        }

        let next = state.withLock { current -> Result<HTTPResponse, HTTPTransportError>? in
            guard !current.queue.isEmpty else {
                return nil
            }

            return current.queue.removeFirst()
        }

        if let next {
            return next
        }

        return .failure(
            HTTPTransportError(
                underlyingError: URLError(.cannotConnectToHost),
                requestLeftDevice: false,
                isCancelled: false,
                isTimedOut: false,
                requestId: "fake-empty-queue",
            )
        )
    }
}
