import Foundation
import KinetixDomain
import Synchronization

public final class FakeSearchRepository: SearchRepository {
    private let suggestResultMutex = Mutex<Result<[String], Failure>>(.success([]))
    private let searchResultMutex = Mutex<Result<SearchResponse, Failure>>(
        .success(
            SearchResponse(
                totalCount: 0,
                hits: [],
                categoryFacets: [],
                indexStatus: SearchIndexStatus(
                    indexedThroughMillis: nil,
                    ageSeconds: nil,
                    isStale: false,
                ),
            )
        )
    )
    private let suggestCallsMutex = Mutex<[String]>([])
    private let searchQueriesMutex = Mutex<[SearchQuery]>([])

    public init() {}

    public func setSuggestResult(_ result: Result<[String], Failure>) {
        suggestResultMutex.withLock { $0 = result }
    }

    public func setSearchResult(_ result: Result<SearchResponse, Failure>) {
        searchResultMutex.withLock { $0 = result }
    }

    public func suggestCalls() -> [String] {
        return suggestCallsMutex.withLock { $0 }
    }

    public func searchQueries() -> [SearchQuery] {
        return searchQueriesMutex.withLock { $0 }
    }

    public func suggestProducts(
        queryText: String,
        limit: Int,
    ) async -> Result<[String], Failure> {
        suggestCallsMutex.withLock { $0.append(queryText) }
        return suggestResultMutex.withLock { $0 }
    }

    public func searchProducts(
        query: SearchQuery
    ) async -> Result<SearchResponse, Failure> {
        searchQueriesMutex.withLock { $0.append(query) }
        return searchResultMutex.withLock { $0 }
    }
}
