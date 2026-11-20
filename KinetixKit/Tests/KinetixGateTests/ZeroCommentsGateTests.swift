import Foundation
import Testing

struct ZeroCommentsGateTests {
    @Test
    func allSwiftFilesContainZeroCommentsExceptToolsVersionDirective() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            let allowToolsVersion = file.relativePath == "KinetixKit/Package.swift"
            let lines = SwiftSourceScanner.findCommentLines(
                in: file.contents,
                allowToolsVersionFirstLine: allowToolsVersion,
            )

            for line in lines {
                violations.append("\(file.relativePath):\(line)")
            }
        }

        #expect(
            violations.isEmpty,
            "Comments found in Swift files: \(violations.joined(separator: ", "))",
        )
    }

    @Test
    func allXcconfigFilesContainNoDoubleSlash() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.xcconfigFiles(in: root)
        var violations: [String] = []

        for file in files {
            let lines = file.contents.components(separatedBy: "\n")
            for (offset, line) in lines.enumerated() where line.contains("//") {
                violations.append("\(file.relativePath):\(offset + 1)")
            }
        }

        #expect(
            violations.isEmpty,
            "Double slash found in xcconfig files: \(violations.joined(separator: ", "))",
        )
    }

    @Test
    func scannerIgnoresURLsInsideStringLiteralsAndCatchesRealComments() {
        let validSource = """
            let url = "https://api.example.test"
            let raw = #"/* not a comment */ // also not"#
            """
        #expect(
            SwiftSourceScanner.findCommentLines(
                in: validSource,
                allowToolsVersionFirstLine: false,
            ).isEmpty
        )

        let invalidSource = """
            let url = "https://api.example.test"
            // real comment
            /* block comment */
            """
        #expect(
            SwiftSourceScanner.findCommentLines(
                in: invalidSource,
                allowToolsVersionFirstLine: false,
            ) == [2, 3]
        )
    }
}
