import Foundation
import Testing

struct HouseLayoutGateTests {
    @Test
    func allSwiftFilesMaintainBlankLineAfterClosingBraceBeforeNextStatement() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            let fileViolations = Self.findCompactClosingBraceViolations(in: file.contents)
            for line in fileViolations {
                violations.append("\(file.relativePath):\(line)")
            }
        }

        #expect(
            violations.isEmpty,
            "Missing blank line after closing brace: \(violations.joined(separator: ", "))",
        )
    }

    @Test
    func layoutCheckerCatchesCompactClosingBraceAndAllowsControlFlowContinuations() {
        let badSource = """
            func sample() {
                if true {
                    work()
                }
                nextStep()
            }
            """
        #expect(Self.findCompactClosingBraceViolations(in: badSource) == [5])

        let goodSource = """
            func sample() {
                if true {
                    work()
                } else {
                    fallback()
                }

                nextStep()
            }
            """
        #expect(Self.findCompactClosingBraceViolations(in: goodSource).isEmpty)
    }

    static func findCompactClosingBraceViolations(in source: String) -> [Int] {
        let stripped = SwiftSourceScanner.stripStringLiterals(from: source)
        let lines = stripped.components(separatedBy: "\n")
        var violations: [Int] = []

        guard lines.count > 1 else {
            return []
        }

        for index in 0..<(lines.count - 1) {
            let current = lines[index].trimmingCharacters(in: .whitespaces)
            let next = lines[index + 1].trimmingCharacters(in: .whitespaces)

            guard current == "}" else {
                continue
            }

            guard !next.isEmpty else {
                continue
            }

            if isAllowedImmediatelyAfterClosingBrace(next) {
                continue
            }

            let currentIndent = leadingSpaceCount(lines[index])
            let nextIndent = leadingSpaceCount(lines[index + 1])

            if nextIndent == currentIndent {
                violations.append(index + 2)
            }
        }

        return violations
    }

    private static func isAllowedImmediatelyAfterClosingBrace(_ trimmedNext: String) -> Bool {
        let allowedPrefixes = [
            "}",
            ")",
            "]",
            ",",
            ".",
            "else",
            "catch",
            "while ",
            "case ",
            "default:",
            "#else",
            "#elseif",
            "#endif",
            "defer",
        ]

        return allowedPrefixes.contains { trimmedNext.hasPrefix($0) }
    }

    private static func leadingSpaceCount(_ line: String) -> Int {
        return line.prefix(while: { $0 == " " }).count
    }
}
