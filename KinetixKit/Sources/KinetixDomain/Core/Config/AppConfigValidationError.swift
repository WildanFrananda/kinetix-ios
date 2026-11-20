import Foundation

public struct AppConfigValidationError: Error, Sendable, Equatable {
    public let issues: [AppConfigIssue]

    public init(issues: [AppConfigIssue]) {
        self.issues = issues
    }
}
