import Foundation

public struct HTTPResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data
    public let requestId: String
    public let requestLeftDevice: Bool

    public init(
        statusCode: Int,
        headers: [String: String],
        body: Data,
        requestId: String,
        requestLeftDevice: Bool = true,
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.requestId = requestId
        self.requestLeftDevice = requestLeftDevice
    }

    public func headerValue(named name: String) -> String? {
        let target = name.lowercased()
        for (key, value) in headers where key.lowercased() == target {
            return value
        }

        return nil
    }
}
