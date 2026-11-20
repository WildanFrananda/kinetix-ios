import Foundation

public struct ServerFailure: Sendable, Equatable, Hashable {
    public let statusCode: Int
    public let code: String?
    public let requestId: String?

    public init(
        statusCode: Int,
        code: String? = nil,
        requestId: String? = nil,
    ) {
        self.statusCode = statusCode
        self.code = code
        self.requestId = requestId
    }
}
