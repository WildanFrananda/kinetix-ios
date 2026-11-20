import Foundation
import Testing

struct FailureHandlingGateTests {
    @Test
    func repositoriesReturnResultWithoutThrowsAndOnlyAllowedTypesTouchTransportErrors() throws {
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
            "Failure handling violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerRejectsThrowingRepositoryAndURLErrorCatchInRepository() {
        let throwingRepo = """
            public protocol BadRepository {
                func load() async throws -> Int
            }
            """
        #expect(
            !Self.checkFile(
                relativePath:
                    "KinetixKit/Sources/KinetixDomain/Repositories/Auth/BadRepository.swift",
                contents: throwingRepo,
            ).isEmpty
        )

        let urlErrorInRepo = """
            public struct DefaultBadRepository {
                func fetch() {
                    let _ = URLError(.timedOut)
                }
            }
            """
        #expect(
            !Self.checkFile(
                relativePath:
                    "KinetixKit/Sources/KinetixData/Repositories/Auth/DefaultBadRepository.swift",
                contents: urlErrorInRepo,
            ).isEmpty
        )
    }

    static func checkFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        var violations: [String] = []
        let stripped = SwiftSourceScanner.stripStringLiterals(from: contents)
        let fileName = URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent

        if relativePath.contains("/Repositories/") {
            let lines = stripped.components(separatedBy: "\n")
            for (offset, line) in lines.enumerated() {
                if line.contains("throws") {
                    violations.append(
                        "\(relativePath):\(offset + 1) repository method must not throw"
                    )
                }
            }
        }

        let allowedTransportInspectors: Set<String> = [
            "SafeApiCaller",
            "TokenRefreshTransport",
            "EdgeEventSocket",
            "URLSessionHTTPTransport",
            "HttpFailureMapper",
            "HTTPResponse",
        ]

        if !allowedTransportInspectors.contains(fileName) {
            if stripped.contains("URLError") {
                violations.append(
                    "\(relativePath): URLError reference outside allowed transport types"
                )
            }

            if stripped.contains("HTTPURLResponse") {
                violations.append(
                    "\(relativePath): HTTPURLResponse reference outside allowed transport types"
                )
            }
        }

        return violations
    }
}
