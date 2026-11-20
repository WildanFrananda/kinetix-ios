import Foundation

struct SwiftDeclaration: Sendable, Equatable {
    let kind: String
    let name: String
    let depth: Int
    let parentName: String?
    let hasModelAttribute: Bool
    let line: Int
}
