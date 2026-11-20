import Foundation

public struct AppConfigInput: Sendable, Equatable {
    public let httpBase: String?
    public let wsBase: String?

    public init(
        httpBase: String?,
        wsBase: String?,
    ) {
        self.httpBase = httpBase
        self.wsBase = wsBase
    }
}
