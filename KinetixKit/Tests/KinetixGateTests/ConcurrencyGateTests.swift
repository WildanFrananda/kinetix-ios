import Foundation
import Testing

struct ConcurrencyGateTests {
    @Test
    func allProductionSourcesForbidBannedConcurrencyAndUnsafeConstructs() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            let isProductionFile =
                file.relativePath.hasPrefix("Kinetix/")
                || file.relativePath.hasPrefix("KinetixKit/Sources/")
            guard isProductionFile else {
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
            "Concurrency/safety violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerRejectsForbiddenConcurrencyConstructsAndDisallowedTaskUsage() {
        let banned = """
            import Combine

            final class Bad: @unchecked Sendable {
                func run() {
                    Task.detached {}
                    DispatchQueue.main.async {}
                    fatalError("boom")
                }
            }
            """
        let findings = Self.checkFile(
            relativePath: "KinetixKit/Sources/KinetixData/Core/Config/Bad.swift",
            contents: banned,
        )
        #expect(findings.count >= 5)

        let taskInDomain = """
            struct BadDomain {
                func run() {
                    Task {
                        print("no")
                    }
                }
            }
            """
        #expect(
            !Self.checkFile(
                relativePath: "KinetixKit/Sources/KinetixDomain/Core/Config/BadDomain.swift",
                contents: taskInDomain,
            ).isEmpty
        )
    }

    static func checkFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        var violations: [String] = []
        let stripped = SwiftSourceScanner.stripStringLiterals(from: contents)
        let imports = SwiftSourceScanner.extractImports(from: contents)

        let forbiddenTokens = [
            "Task.detached",
            "DispatchQueue",
            "@unchecked Sendable",
            "nonisolated(unsafe)",
            "ObservableObject",
            "@Published",
            "@EnvironmentObject",
            "try!",
            "fatalError(",
        ]

        for token in forbiddenTokens where stripped.contains(token) {
            violations.append("\(relativePath): forbidden construct \(token)")
        }

        let isFirebaseAdapter = relativePath.hasPrefix("Kinetix/Adapters/Firebase/")
        for item in imports {
            if item.module == "Combine" {
                violations.append("\(relativePath):\(item.line) Combine import is forbidden")
            }

            if item.isPreconcurrency && !isFirebaseAdapter {
                violations.append(
                    "\(relativePath):\(item.line) @preconcurrency import outside Kinetix/Adapters/Firebase/"
                )
            }
        }

        if stripped.contains("Task {") || stripped.contains("Task{") {
            let isAllowedTaskLocation =
                relativePath.contains("/ViewModels/")
                || relativePath.contains("/Services/Session/")
                || relativePath.contains("/Services/Outbox/")
                || relativePath.contains("/Services/Realtime/")
                || relativePath.hasPrefix("Kinetix/App/")
                || relativePath.hasPrefix("Kinetix/Adapters/")
            if !isAllowedTaskLocation {
                violations.append("\(relativePath): unstructured Task outside allowed locations")
            }
        }

        return violations
    }
}
