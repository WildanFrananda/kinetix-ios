import Foundation

public struct AppConfig: Sendable, Equatable {
    public let httpBaseURL: URL
    public let wsBaseURL: URL

    public init(
        httpBaseURL: URL,
        wsBaseURL: URL,
    ) {
        self.httpBaseURL = httpBaseURL
        self.wsBaseURL = wsBaseURL
    }
}
