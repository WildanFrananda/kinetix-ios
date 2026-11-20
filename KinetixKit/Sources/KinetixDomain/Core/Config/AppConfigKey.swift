import Foundation

public enum AppConfigKey: String, CaseIterable, Sendable, Equatable, Hashable {
    case httpBase = "KINETIX_HTTP_BASE"
    case wsBase = "KINETIX_WS_BASE"
}
