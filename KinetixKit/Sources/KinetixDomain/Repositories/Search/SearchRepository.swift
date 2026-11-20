import Foundation

public protocol SearchRepository: Sendable {
    func suggestProducts(
        queryText: String,
        limit: Int,
    ) async -> Result<[String], Failure>

    func searchProducts(
        query: SearchQuery
    ) async -> Result<SearchResponse, Failure>
}
