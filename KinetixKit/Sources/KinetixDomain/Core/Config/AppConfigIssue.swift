import Foundation

public struct AppConfigIssue: Sendable, Equatable, Hashable {
    public let key: AppConfigKey
    public let kind: AppConfigIssueKind

    public init(
        key: AppConfigKey,
        kind: AppConfigIssueKind,
    ) {
        self.key = key
        self.kind = kind
    }
}
