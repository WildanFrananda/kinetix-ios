import Foundation
import KinetixDomain
import KinetixPresentation
import Testing

@testable import Kinetix

struct KinetixTests {
    @Test
    @MainActor
    func appContainerBuildsRootViewModelInValidatingState() {
        let container = AppContainer(bundle: .main)
        let viewModel = container.makeRootViewModel()

        #expect(viewModel.state == .validating)
    }

    @Test
    @MainActor
    func rootViewModelReportsMissingConfigurationWhenLocalConfigIsAbsent() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-host-empty-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "com.kinetix.shop.test.empty"
        ]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0,
        )
        try plistData.write(to: tempRoot.appendingPathComponent("Info.plist"))

        let bundle = try #require(Bundle(url: tempRoot))
        let container = AppContainer(bundle: bundle)
        let viewModel = container.makeRootViewModel()

        viewModel.start()

        #expect(
            viewModel.state
                == .invalidConfiguration([
                    AppConfigIssue(key: .httpBase, kind: .missing),
                    AppConfigIssue(key: .wsBase, kind: .missing),
                ])
        )
    }
}
