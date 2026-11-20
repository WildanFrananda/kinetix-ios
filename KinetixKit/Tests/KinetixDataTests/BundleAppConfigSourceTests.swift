import Foundation
import KinetixData
import KinetixDomain
import Testing

struct BundleAppConfigSourceTests {
    @Test
    func readsConfiguredBaseURLsFromBundleInfoDictionary() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-bundle-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "com.kinetix.test.bundle",
            AppConfigKey.httpBase.rawValue: "https://api.example.test",
            AppConfigKey.wsBase.rawValue: "wss://api.example.test",
        ]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0,
        )
        try plistData.write(to: tempRoot.appendingPathComponent("Info.plist"))

        let bundle = try #require(Bundle(url: tempRoot))
        let source = BundleAppConfigSource(bundle: bundle)

        let raw = source.readRawConfig()

        #expect(raw.httpBase == "https://api.example.test")
        #expect(raw.wsBase == "wss://api.example.test")
    }

    @Test
    func returnsNilWhenKeysAreAbsentFromBundle() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("kinetix-empty-bundle-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "com.kinetix.test.empty"
        ]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0,
        )
        try plistData.write(to: tempRoot.appendingPathComponent("Info.plist"))

        let bundle = try #require(Bundle(url: tempRoot))
        let source = BundleAppConfigSource(bundle: bundle)

        let raw = source.readRawConfig()

        #expect(raw.httpBase == nil)
        #expect(raw.wsBase == nil)
    }
}
