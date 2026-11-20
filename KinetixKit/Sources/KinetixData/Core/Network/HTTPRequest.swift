import Foundation

public struct HTTPRequest: Sendable, Equatable {
    public let method: HTTPMethod
    public let path: String
    public let headers: [String: String]
    public let body: Data?
    public let isWrite: Bool
    public let hasOwnUnauthorized: Bool
    public let requiresAuth: Bool
    public let timeoutSeconds: TimeInterval?

    public init(
        method: HTTPMethod,
        path: String,
        headers: [String: String] = [:],
        body: Data? = nil,
        isWrite: Bool = false,
        hasOwnUnauthorized: Bool = false,
        requiresAuth: Bool = false,
        timeoutSeconds: TimeInterval? = nil,
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
        self.isWrite = isWrite
        self.hasOwnUnauthorized = hasOwnUnauthorized
        self.requiresAuth = requiresAuth
        self.timeoutSeconds = timeoutSeconds
    }
}
