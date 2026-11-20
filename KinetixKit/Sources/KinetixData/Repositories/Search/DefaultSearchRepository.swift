import Foundation
import KinetixDomain

public struct DefaultSearchRepository: SearchRepository {
    private let apiClient: SearchAPIClient
    private let suggestCoalescer = InFlightReadCoalescer<
        String,
        Result<[String], Failure>
    >()
    private let searchCoalescer = InFlightReadCoalescer<
        SearchQuery,
        Result<SearchResponse, Failure>
    >()

    public init(apiClient: SearchAPIClient) {
        self.apiClient = apiClient
    }

    public func suggestProducts(
        queryText: String,
        limit: Int,
    ) async -> Result<[String], Failure> {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .success([])
        }

        let apiClient = self.apiClient
        let clampedLimit = min(max(1, limit), 20)
        let coalescerKey = "\(trimmed)|\(clampedLimit)"

        return await suggestCoalescer.coalesce(key: coalescerKey) {
            return await apiClient.suggestProducts(queryText: trimmed, limit: clampedLimit)
        }
    }

    public func searchProducts(query: SearchQuery) async -> Result<SearchResponse, Failure> {
        let apiClient = self.apiClient
        return await searchCoalescer.coalesce(key: query) {
            return await apiClient.searchProducts(query: query)
        }
    }
}
