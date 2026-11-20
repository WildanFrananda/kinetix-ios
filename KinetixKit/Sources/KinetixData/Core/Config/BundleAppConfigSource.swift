import Foundation
import KinetixDomain

public struct BundleAppConfigSource: AppConfigSource {
    private let httpBase: String?
    private let wsBase: String?

    public init(bundle: Bundle) {
        self.httpBase =
            bundle.object(forInfoDictionaryKey: AppConfigKey.httpBase.rawValue) as? String
        self.wsBase =
            bundle.object(forInfoDictionaryKey: AppConfigKey.wsBase.rawValue) as? String
    }

    public func readRawConfig() -> AppConfigInput {
        return AppConfigInput(
            httpBase: httpBase,
            wsBase: wsBase,
        )
    }
}
