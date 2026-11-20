import Foundation

public struct AppConfigValidator: Sendable {
    public init() {}

    public func validate(_ input: AppConfigInput) -> Result<AppConfig, AppConfigValidationError> {
        var issues: [AppConfigIssue] = []

        let httpURL = parseBaseURL(
            raw: input.httpBase,
            key: .httpBase,
            requiredScheme: "https",
            issues: &issues,
        )

        let wsURL = parseBaseURL(
            raw: input.wsBase,
            key: .wsBase,
            requiredScheme: "wss",
            issues: &issues,
        )

        if let httpURL, let wsURL, issues.isEmpty {
            return .success(
                AppConfig(
                    httpBaseURL: httpURL,
                    wsBaseURL: wsURL,
                )
            )
        }

        return .failure(AppConfigValidationError(issues: issues))
    }

    private func parseBaseURL(
        raw: String?,
        key: AppConfigKey,
        requiredScheme: String,
        issues: inout [AppConfigIssue],
    ) -> URL? {
        guard let raw else {
            issues.append(AppConfigIssue(key: key, kind: .missing))
            return nil
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "$(\(key.rawValue))" {
            issues.append(AppConfigIssue(key: key, kind: .missing))
            return nil
        }

        let requiredPrefix = "\(requiredScheme)://"
        guard trimmed.lowercased().hasPrefix(requiredPrefix) else {
            issues.append(AppConfigIssue(key: key, kind: .malformed))
            return nil
        }

        guard let components = URLComponents(string: trimmed) else {
            issues.append(AppConfigIssue(key: key, kind: .malformed))
            return nil
        }

        guard
            components.scheme?.lowercased() == requiredScheme,
            let host = components.host,
            !host.isEmpty,
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil,
            let url = components.url
        else {
            issues.append(AppConfigIssue(key: key, kind: .malformed))
            return nil
        }

        return url
    }
}
