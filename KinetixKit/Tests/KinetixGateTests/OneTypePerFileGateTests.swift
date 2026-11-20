import Foundation
import Testing

struct OneTypePerFileGateTests {
    @Test
    func everySwiftFileDeclaresAtMostOneTopLevelTypeMatchingItsFilename() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            if file.relativePath == "KinetixKit/Package.swift" {
                continue
            }

            let fileViolations = Self.checkFile(
                relativePath: file.relativePath,
                contents: file.contents,
            )
            violations.append(contentsOf: fileViolations)
        }

        #expect(
            violations.isEmpty,
            "One-type-per-file violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerRejectsMultipleTypesWrongNameAndNestedTypesButAllowsCodingKeysAndSchemaModel() {
        let twoTypes = """
            struct First {}
            struct Second {}
            """
        #expect(!Self.checkFile(relativePath: "First.swift", contents: twoTypes).isEmpty)

        let nestedType = """
            struct Outer {
                enum Inner {}
            }
            """
        #expect(!Self.checkFile(relativePath: "Outer.swift", contents: nestedType).isEmpty)

        let codingKeys = """
            struct ProductDTO: Decodable {
                enum CodingKeys: String, CodingKey {
                    case id
                }
            }
            """
        #expect(Self.checkFile(relativePath: "ProductDTO.swift", contents: codingKeys).isEmpty)

        let schemaModel = """
            extension LedgerSchemaV1 {
                @Model
                final class OutboxEntry {}
            }
            """
        #expect(
            Self.checkFile(
                relativePath: "LedgerSchemaV1+OutboxEntry.swift",
                contents: schemaModel,
            ).isEmpty
        )
    }

    static func checkFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        let fileName = URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent
        let declarations = SwiftSourceScanner.extractDeclarations(from: contents)
        let typeKinds: Set<String> = ["struct", "class", "enum", "actor", "protocol"]
        var violations: [String] = []

        let topLevelTypes = declarations.filter { $0.depth == 0 && typeKinds.contains($0.kind) }
        let topLevelExtensions = declarations.filter { $0.depth == 0 && $0.kind == "extension" }
        let nestedTypes = declarations.filter { $0.depth > 0 && typeKinds.contains($0.kind) }

        if fileName.contains("+") {
            let parts = fileName.split(separator: "+", maxSplits: 1).map(String.init)
            let extendedType = parts[0]
            let aspectName = parts.count > 1 ? parts[1] : ""

            if !topLevelTypes.isEmpty {
                violations.append(
                    "\(relativePath): extension file must not declare top-level types"
                )
            }

            for ext in topLevelExtensions where ext.name != extendedType {
                violations.append(
                    "\(relativePath):\(ext.line) extends \(ext.name) instead of \(extendedType)"
                )
            }

            for nested in nestedTypes {
                let isAllowedSchemaModel =
                    nested.hasModelAttribute
                    && nested.kind == "class"
                    && nested.name == aspectName
                    && nested.parentName == extendedType
                if !isAllowedSchemaModel {
                    violations.append(
                        "\(relativePath):\(nested.line) disallowed nested type \(nested.name)"
                    )
                }
            }

            return violations
        }

        if topLevelTypes.count > 1 {
            let names = topLevelTypes.map(\.name).joined(separator: ", ")
            violations.append("\(relativePath): declares multiple top-level types (\(names))")
        }

        if let primary = topLevelTypes.first, primary.name != fileName {
            violations.append(
                "\(relativePath):\(primary.line) declares \(primary.name) in \(fileName).swift"
            )
        }

        for nested in nestedTypes {
            let isCodingKeys = nested.kind == "enum" && nested.name == "CodingKeys"
            if !isCodingKeys {
                violations.append(
                    "\(relativePath):\(nested.line) disallowed nested type \(nested.name)"
                )
            }
        }

        return violations
    }
}
