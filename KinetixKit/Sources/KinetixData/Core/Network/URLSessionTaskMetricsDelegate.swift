import Foundation
import Synchronization

final class URLSessionTaskMetricsDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    private let state = Mutex<Bool?>(nil)

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics,
    ) {
        let leftDevice = Self.didRequestLeaveDevice(metrics: metrics)
        state.withLock { value in
            value = leftDevice
        }
    }

    func resolvedRequestLeftDevice() -> Bool {
        return state.withLock { value in
            return value ?? true
        }
    }

    static func didRequestLeaveDevice(metrics: URLSessionTaskMetrics) -> Bool {
        return metrics.transactionMetrics.contains { transaction in
            transaction.countOfRequestHeaderBytesSent > 0 || transaction.requestStartDate != nil
        }
    }
}
