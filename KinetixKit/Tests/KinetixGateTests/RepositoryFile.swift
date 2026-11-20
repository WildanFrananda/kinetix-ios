import Foundation

struct RepositoryFile: Sendable {
    let relativePath: String
    let url: URL
    let contents: String
}
