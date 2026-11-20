import Foundation
import KinetixDomain

public struct FakeAppConfigSource: AppConfigSource {
    private let input: AppConfigInput

    public init(input: AppConfigInput) {
        self.input = input
    }

    public func readRawConfig() -> AppConfigInput {
        return input
    }
}
