import Foundation

struct SwiftSourceScanner: Sendable {
    static func findCommentLines(
        in source: String,
        allowToolsVersionFirstLine: Bool,
    ) -> [Int] {
        let chars = Array(source)
        let count = chars.count
        var index = 0
        var line = 1
        var commentLines: [Int] = []

        while index < count {
            let ch = chars[index]

            if ch == "\n" {
                line += 1
                index += 1
                continue
            }

            if ch == "#" {
                let hashStart = index
                var hashes = 0
                while index < count && chars[index] == "#" {
                    hashes += 1
                    index += 1
                }

                if index < count && chars[index] == "\"" {
                    skipStringLiteral(
                        chars: chars,
                        index: &index,
                        line: &line,
                        hashes: hashes,
                    )
                    continue
                }

                index = hashStart + 1
                continue
            }

            if ch == "\"" {
                skipStringLiteral(
                    chars: chars,
                    index: &index,
                    line: &line,
                    hashes: 0,
                )
                continue
            }

            if ch == "/" && index + 1 < count {
                let next = chars[index + 1]
                if next == "/" {
                    let lineStart = index
                    while index < count && chars[index] != "\n" {
                        index += 1
                    }

                    let text = String(chars[lineStart..<index])
                    let isAllowedToolsVersion =
                        allowToolsVersionFirstLine
                        && line == 1
                        && text.hasPrefix("// swift-tools-version:")
                    if !isAllowedToolsVersion {
                        commentLines.append(line)
                    }

                    continue
                }

                if next == "*" {
                    commentLines.append(line)
                    index += 2
                    var nesting = 1
                    while index < count && nesting > 0 {
                        if chars[index] == "\n" {
                            line += 1
                            index += 1
                        } else if chars[index] == "/" && index + 1 < count
                            && chars[index + 1] == "*"
                        {
                            nesting += 1
                            index += 2
                        } else if chars[index] == "*" && index + 1 < count
                            && chars[index + 1] == "/"
                        {
                            nesting -= 1
                            index += 2
                        } else {
                            index += 1
                        }
                    }

                    continue
                }
            }

            index += 1
        }

        return commentLines
    }

    static func stripStringLiterals(from source: String) -> String {
        let chars = Array(source)
        let count = chars.count
        var index = 0
        var line = 1
        var output: [Character] = []
        output.reserveCapacity(count)

        while index < count {
            let ch = chars[index]

            if ch == "#" {
                let hashStart = index
                var hashes = 0
                while index < count && chars[index] == "#" {
                    hashes += 1
                    index += 1
                }

                if index < count && chars[index] == "\"" {
                    skipStringLiteral(
                        chars: chars,
                        index: &index,
                        line: &line,
                        hashes: hashes,
                    )
                    for pos in hashStart..<index {
                        output.append(chars[pos] == "\n" ? "\n" : " ")
                    }

                    continue
                }

                output.append(chars[hashStart])
                index = hashStart + 1
                continue
            }

            if ch == "\"" {
                let startIndex = index
                skipStringLiteral(
                    chars: chars,
                    index: &index,
                    line: &line,
                    hashes: 0,
                )
                for pos in startIndex..<index {
                    output.append(chars[pos] == "\n" ? "\n" : " ")
                }

                continue
            }

            if ch == "\n" {
                line += 1
            }

            output.append(ch)
            index += 1
        }

        return String(output)
    }

    static func extractImports(
        from source: String
    ) -> [(module: String, isPreconcurrency: Bool, line: Int)] {
        let stripped = stripStringLiterals(from: source)
        let lines = stripped.components(separatedBy: "\n")
        var imports: [(module: String, isPreconcurrency: Bool, line: Int)] = []

        for (offset, rawLine) in lines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard let importIndex = tokens.firstIndex(of: "import") else {
                continue
            }

            let prefix = tokens[0..<importIndex]
            let validPrefixes: Set<String> = [
                "@testable",
                "@preconcurrency",
                "public",
                "internal",
                "private",
                "fileprivate",
                "package",
            ]
            guard prefix.allSatisfy({ validPrefixes.contains($0) }) else {
                continue
            }

            guard importIndex + 1 < tokens.count else {
                continue
            }

            var moduleIndex = importIndex + 1
            let importKinds: Set<String> = [
                "typealias",
                "struct",
                "class",
                "enum",
                "protocol",
                "let",
                "var",
                "func",
            ]
            if importKinds.contains(tokens[moduleIndex]) {
                moduleIndex += 1
            }

            guard moduleIndex < tokens.count else {
                continue
            }

            let moduleName = tokens[moduleIndex].split(separator: ".").first.map(String.init) ?? ""
            guard !moduleName.isEmpty else {
                continue
            }

            let isPreconcurrency = prefix.contains("@preconcurrency")
            imports.append(
                (module: moduleName, isPreconcurrency: isPreconcurrency, line: offset + 1)
            )
        }

        return imports
    }

    static func extractDeclarations(from source: String) -> [SwiftDeclaration] {
        let stripped = stripStringLiterals(from: source)
        let lines = stripped.components(separatedBy: "\n")
        let typeKinds: Set<String> = [
            "struct",
            "class",
            "enum",
            "actor",
            "protocol",
            "extension",
            "typealias",
        ]
        let allowedModifiers: Set<String> = [
            "public",
            "internal",
            "private",
            "fileprivate",
            "package",
            "open",
            "final",
            "indirect",
            "nonisolated",
            "distributed",
            "isolated",
            "consuming",
            "borrowing",
        ]

        var declarations: [SwiftDeclaration] = []
        var braceDepth = 0
        var scopeStack: [(name: String, depth: Int)] = []
        var pendingModelAttribute = false

        for (offset, rawLine) in lines.enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            let lineNumber = offset + 1

            if trimmed.hasPrefix("@Model") {
                pendingModelAttribute = true
            }

            if !trimmed.isEmpty {
                let words = tokenizeHeaderWords(trimmed)
                var cursor = 0
                var seenModelOnLine = false

                while cursor < words.count {
                    let word = words[cursor]
                    if word.hasPrefix("@") {
                        if word == "@Model" {
                            seenModelOnLine = true
                        }

                        cursor += 1
                        continue
                    }

                    if allowedModifiers.contains(word) {
                        cursor += 1
                        continue
                    }

                    break
                }

                if cursor + 1 < words.count && typeKinds.contains(words[cursor]) {
                    let kind = words[cursor]
                    let name = words[cursor + 1]
                    let parentName = scopeStack.last?.name
                    declarations.append(
                        SwiftDeclaration(
                            kind: kind,
                            name: name,
                            depth: braceDepth,
                            parentName: parentName,
                            hasModelAttribute: pendingModelAttribute || seenModelOnLine,
                            line: lineNumber,
                        )
                    )
                    pendingModelAttribute = false

                    if kind != "typealias" {
                        let opensCount = rawLine.filter { $0 == "{" }.count
                        let closesCount = rawLine.filter { $0 == "}" }.count
                        if opensCount > closesCount {
                            scopeStack.append((name: name, depth: braceDepth + 1))
                        }
                    }
                } else if !trimmed.hasPrefix("@") {
                    pendingModelAttribute = false
                }
            }

            for ch in rawLine {
                if ch == "{" {
                    braceDepth += 1
                } else if ch == "}" {
                    braceDepth = max(0, braceDepth - 1)
                    while let top = scopeStack.last, top.depth > braceDepth {
                        scopeStack.removeLast()
                    }
                }
            }
        }

        return declarations
    }

    private static func tokenizeHeaderWords(_ line: String) -> [String] {
        var words: [String] = []
        var current = ""
        var parenDepth = 0

        for ch in line {
            if ch == "(" {
                parenDepth += 1
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }

                continue
            }

            if ch == ")" {
                parenDepth = max(0, parenDepth - 1)
                continue
            }

            if parenDepth > 0 {
                continue
            }

            if ch.isWhitespace || ch == ":" || ch == "{" || ch == "<" || ch == "," || ch == "=" {
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
        }

        if !current.isEmpty {
            words.append(current)
        }

        return words
    }

    private static func skipStringLiteral(
        chars: [Character],
        index: inout Int,
        line: inout Int,
        hashes: Int,
    ) {
        let count = chars.count
        let isMultiline =
            index + 2 < count
            && chars[index] == "\""
            && chars[index + 1] == "\""
            && chars[index + 2] == "\""

        if isMultiline {
            index += 3
            while index < count {
                if chars[index] == "\n" {
                    line += 1
                    index += 1
                    continue
                }

                if chars[index] == "\\" && hashes == 0 {
                    index += 2
                    continue
                }

                if chars[index] == "\""
                    && index + 2 < count
                    && chars[index + 1] == "\""
                    && chars[index + 2] == "\""
                {
                    let matched = matchesClosingHashes(
                        chars: chars,
                        afterQuoteIndex: index + 3,
                        hashes: hashes,
                    )
                    if matched {
                        index += 3 + hashes
                        return
                    }
                }

                index += 1
            }

            return
        }

        index += 1
        while index < count {
            if chars[index] == "\n" {
                line += 1
                index += 1
                return
            }

            if chars[index] == "\\" && hashes == 0 {
                index += 2
                continue
            }

            if chars[index] == "\"" {
                if matchesClosingHashes(chars: chars, afterQuoteIndex: index + 1, hashes: hashes) {
                    index += 1 + hashes
                    return
                }
            }

            index += 1
        }
    }

    private static func matchesClosingHashes(
        chars: [Character],
        afterQuoteIndex: Int,
        hashes: Int,
    ) -> Bool {
        guard hashes > 0 else {
            return true
        }

        guard afterQuoteIndex + hashes <= chars.count else {
            return false
        }

        for offset in 0..<hashes {
            if chars[afterQuoteIndex + offset] != "#" {
                return false
            }
        }

        return true
    }
}
