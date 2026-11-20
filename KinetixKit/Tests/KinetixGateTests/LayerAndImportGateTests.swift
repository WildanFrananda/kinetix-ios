import Foundation
import Testing

struct LayerAndImportGateTests {
    @Test
    func importsAndFolderStructureRespectLayerBoundaries() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            if file.relativePath == "KinetixKit/Package.swift" {
                continue
            }

            violations.append(
                contentsOf: Self.checkFile(
                    relativePath: file.relativePath,
                    contents: file.contents,
                )
            )
        }

        #expect(
            violations.isEmpty,
            "Layer/import violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerRejectsForbiddenImportsDirectFilesInFeatureContainersUseCasesAndSingletons() {
        let domainSwiftUI = "import Foundation\nimport SwiftUI\nstruct Foo {}"
        #expect(
            !Self.checkFile(
                relativePath: "KinetixKit/Sources/KinetixDomain/Core/Config/Foo.swift",
                contents: domainSwiftUI,
            ).isEmpty
        )

        let directModelFile = "import Foundation\nstruct Foo {}"
        #expect(
            !Self.checkFile(
                relativePath: "KinetixKit/Sources/KinetixDomain/Models/Foo.swift",
                contents: directModelFile,
            ).isEmpty
        )

        let firebaseOutsideAdapter = "import FirebaseMessaging\nstruct Push {}"
        #expect(
            !Self.checkFile(
                relativePath: "Kinetix/App/Push.swift",
                contents: firebaseOutsideAdapter,
            ).isEmpty
        )

        let singletonOutsideContainer = """
            import Foundation

            struct Session {
                static let shared = Session()
            }
            """
        #expect(
            !Self.checkFile(
                relativePath: "KinetixKit/Sources/KinetixData/Core/Config/Session.swift",
                contents: singletonOutsideContainer,
            ).isEmpty
        )
    }

    static func checkFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        var violations: [String] = []
        let components = relativePath.split(separator: "/").map(String.init)
        let imports = SwiftSourceScanner.extractImports(from: contents)

        let featureContainerParents: Set<String> = [
            "Models",
            "Repositories",
            "DTO",
            "Services",
            "State",
            "ViewModels",
        ]

        if components.count >= 2 {
            let parent = components[components.count - 2]
            if featureContainerParents.contains(parent) {
                violations.append(
                    "\(relativePath): must live inside a feature subfolder under \(parent)/"
                )
            }

            if components.count >= 3
                && components[components.count - 3] == "UI"
                && parent == "Screens"
            {
                violations.append(
                    "\(relativePath): must live inside a feature subfolder under UI/Screens/"
                )
            }
        }

        let fileName = URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent
        if fileName.contains("UseCase") || fileName.contains("Interactor") {
            violations.append("\(relativePath): UseCase/Interactor layer is forbidden")
        }

        let stripped = SwiftSourceScanner.stripStringLiterals(from: contents)
        if fileName != "AppContainer" && stripped.contains("static let shared") {
            violations.append("\(relativePath): singleton static let shared outside AppContainer")
        }

        let allowedImports = Self.allowedImports(for: relativePath)
        let isFirebaseAdapter = relativePath.hasPrefix("Kinetix/Adapters/Firebase/")

        for item in imports {
            if item.module.hasPrefix("Firebase") && !isFirebaseAdapter {
                violations.append(
                    "\(relativePath):\(item.line) Firebase import outside Kinetix/Adapters/Firebase/"
                )
            }

            if let allowedImports, !allowedImports.contains(item.module) {
                violations.append(
                    "\(relativePath):\(item.line) disallowed import \(item.module)"
                )
            }
        }

        return violations
    }

    private static func allowedImports(for relativePath: String) -> Set<String>? {
        if relativePath.hasPrefix("KinetixKit/Sources/KinetixDomain/") {
            return ["Foundation"]
        }

        if relativePath.hasPrefix("KinetixKit/Sources/KinetixPresentation/") {
            return ["Foundation", "Observation", "KinetixDomain"]
        }

        if relativePath.hasPrefix("KinetixKit/Sources/KinetixData/") {
            return [
                "KinetixDomain",
                "Foundation",
                "SwiftData",
                "Security",
                "Network",
                "OSLog",
                "CryptoKit",
                "Synchronization",
            ]
        }

        if relativePath.hasPrefix("KinetixKit/Tests/KinetixFakes/") {
            return [
                "KinetixDomain",
                "Foundation",
                "Testing",
                "Synchronization",
            ]
        }

        if relativePath.hasPrefix("KinetixKit/Tests/KinetixDomainTests/") {
            return [
                "KinetixDomain",
                "KinetixFakes",
                "Foundation",
                "Testing",
                "Synchronization",
            ]
        }

        if relativePath.hasPrefix("KinetixKit/Tests/KinetixDataTests/") {
            return [
                "KinetixDomain",
                "KinetixData",
                "KinetixFakes",
                "Foundation",
                "SwiftData",
                "Security",
                "Network",
                "OSLog",
                "CryptoKit",
                "Testing",
                "Synchronization",
            ]
        }

        if relativePath.hasPrefix("KinetixKit/Tests/KinetixPresentationTests/") {
            return [
                "KinetixDomain",
                "KinetixPresentation",
                "KinetixFakes",
                "Foundation",
                "Observation",
                "Testing",
                "Synchronization",
            ]
        }

        if relativePath.hasPrefix("KinetixKit/Tests/KinetixGateTests/") {
            return [
                "Foundation",
                "Testing",
                "Synchronization",
            ]
        }

        return nil
    }
}
