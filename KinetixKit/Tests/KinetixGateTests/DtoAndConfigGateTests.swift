import Foundation
import Testing

struct DtoAndConfigGateTests {
    @Test
    func dtosAndProductionSourcesRespectCodingKeysAndNoHardcodedHosts() throws {
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
                contentsOf: Self.checkProductionFile(
                    relativePath: file.relativePath,
                    contents: file.contents,
                )
            )
        }

        #expect(
            violations.isEmpty,
            "DTO/config violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerCatchesMissingCodingKeysGlobalKeyStrategyAndHardcodedHostURL() {
        let dtoWithoutCodingKeys = """
            struct SampleDTO: Decodable {
                let id: String
            }
            """
        #expect(
            !Self.checkProductionFile(
                relativePath: "KinetixKit/Sources/KinetixData/DTO/Auth/SampleDTO.swift",
                contents: dtoWithoutCodingKeys,
            ).isEmpty
        )

        let globalStrategy = """
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            """
        #expect(
            !Self.checkProductionFile(
                relativePath: "KinetixKit/Sources/KinetixData/Core/Network/Client.swift",
                contents: globalStrategy,
            ).isEmpty
        )

        let hardcodedHost = """
            let url = "https://api.wildanfrananda.my.id/api/v1/auth/me"
            """
        #expect(
            !Self.checkProductionFile(
                relativePath: "Kinetix/App/AppContainer.swift",
                contents: hardcodedHost,
            ).isEmpty
        )
    }

    static func checkProductionFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        var violations: [String] = []

        if relativePath.contains("/DTO/") {
            let declarations = SwiftSourceScanner.extractDeclarations(from: contents)
            let hasCodingKeys = declarations.contains {
                $0.depth > 0 && $0.kind == "enum" && $0.name == "CodingKeys"
            }

            if !hasCodingKeys {
                violations.append("\(relativePath): DTO must declare CodingKeys")
            }
        }

        let stripped = SwiftSourceScanner.stripStringLiterals(from: contents)
        if stripped.contains(".convertFromSnakeCase") || stripped.contains(".convertToSnakeCase") {
            violations.append("\(relativePath): global JSON key strategy is forbidden")
        }

        if contents.contains("https://") || contents.contains("wss://") {
            violations.append(
                "\(relativePath): hardcoded https:// or wss:// URL in production source"
            )
        }

        if contents.contains("wildanfrananda.my.id") {
            violations.append("\(relativePath): hardcoded Kinetix host in production source")
        }

        return violations
    }
}
