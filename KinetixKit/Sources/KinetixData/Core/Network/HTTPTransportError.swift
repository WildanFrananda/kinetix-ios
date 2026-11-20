import Foundation

public struct HTTPTransportError: Error, Sendable {
    public let underlyingError: any Error
    public let requestLeftDevice: Bool
    public let isCancelled: Bool
    public let isTimedOut: Bool
    public let requestId: String

    public init(
        underlyingError: any Error,
        requestLeftDevice: Bool,
        isCancelled: Bool,
        isTimedOut: Bool,
        requestId: String,
    ) {
        self.underlyingError = underlyingError
        self.requestLeftDevice = requestLeftDevice
        self.isCancelled = isCancelled
        self.isTimedOut = isTimedOut
        self.requestId = requestId
    }
}
