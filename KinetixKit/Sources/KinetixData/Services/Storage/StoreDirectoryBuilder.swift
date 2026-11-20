import Foundation

public struct StoreDirectoryBuilder: Sendable {
    public static func storeURL(
        subdirectory: String,
        filename: String,
        baseDirectory: URL? = nil,
    ) throws -> URL {
        let root: URL
        if let baseDirectory {
            root = baseDirectory
        } else {
            root = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true,
            )
        }

        var directory = root.appendingPathComponent(subdirectory, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try directory.setResourceValues(resourceValues)

        #if os(iOS)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: directory.path,
            )
        #endif

        return directory.appendingPathComponent(filename)
    }
}
