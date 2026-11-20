import Foundation

struct RepositoryLocator: Sendable {
    static func repositoryRoot(from filePath: StaticString = #filePath) throws -> URL {
        var current = URL(fileURLWithPath: "\(filePath)").deletingLastPathComponent()

        while current.path != "/" {
            let marker = current.appendingPathComponent("Kinetix.xcodeproj")
            if FileManager.default.fileExists(atPath: marker.path) {
                return current
            }

            current.deleteLastPathComponent()
        }

        throw CocoaError(.fileNoSuchFile)
    }

    static func swiftFiles(in root: URL) throws -> [RepositoryFile] {
        let searchRoots = [
            "Kinetix",
            "KinetixTests",
            "KinetixUITests",
            "KinetixKit/Sources",
            "KinetixKit/Tests",
        ]

        var files: [RepositoryFile] = []

        let packageManifest = root.appendingPathComponent("KinetixKit/Package.swift")
        if FileManager.default.fileExists(atPath: packageManifest.path) {
            let contents = try String(contentsOf: packageManifest, encoding: .utf8)
            files.append(
                RepositoryFile(
                    relativePath: "KinetixKit/Package.swift",
                    url: packageManifest,
                    contents: contents,
                )
            )
        }

        for folder in searchRoots {
            let baseURL = root.appendingPathComponent(folder)
            guard FileManager.default.fileExists(atPath: baseURL.path) else {
                continue
            }

            guard
                let enumerator = FileManager.default.enumerator(
                    at: baseURL,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles],
                )
            else {
                continue
            }

            while let next = enumerator.nextObject() as? URL {
                guard next.pathExtension == "swift" else {
                    continue
                }

                let relativePath = next.path.replacingOccurrences(of: root.path + "/", with: "")
                let contents = try String(contentsOf: next, encoding: .utf8)
                files.append(
                    RepositoryFile(
                        relativePath: relativePath,
                        url: next,
                        contents: contents,
                    )
                )
            }
        }

        return files.sorted { $0.relativePath < $1.relativePath }
    }

    static func xcconfigFiles(in root: URL) throws -> [RepositoryFile] {
        let configDir = root.appendingPathComponent("Configuration")
        guard FileManager.default.fileExists(atPath: configDir.path) else {
            return []
        }

        let entries = try FileManager.default.contentsOfDirectory(
            at: configDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
        )

        var files: [RepositoryFile] = []

        for entry in entries {
            let fileName = entry.lastPathComponent
            guard fileName.hasSuffix(".xcconfig") || fileName.hasSuffix(".xcconfig.example") else {
                continue
            }

            guard fileName != "Local.xcconfig" else {
                continue
            }

            let relativePath = entry.path.replacingOccurrences(of: root.path + "/", with: "")
            let contents = try String(contentsOf: entry, encoding: .utf8)
            files.append(
                RepositoryFile(
                    relativePath: relativePath,
                    url: entry,
                    contents: contents,
                )
            )
        }

        return files.sorted { $0.relativePath < $1.relativePath }
    }
}
