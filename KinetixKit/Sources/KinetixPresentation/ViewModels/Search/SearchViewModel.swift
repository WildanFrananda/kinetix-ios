import Foundation
import KinetixDomain
import Observation

@Observable
public final class SearchViewModel {
    private static let defaultLimit = 20
    private static let suggestionLimit = 5
    private static let debounceMilliseconds = 250

    public var queryText = ""
    public private(set) var suggestions: [String] = []
    public private(set) var selectedCategorySlug: CategorySlug?
    public private(set) var selectedSort: SearchSortOption = .relevance
    public private(set) var categoryNamesBySlug: [CategorySlug: String] = [:]
    public private(set) var state: SearchScreenState = .idle
    public private(set) var isLoadingMore = false

    private let searchRepository: any SearchRepository
    private let catalogRepository: any CatalogRepository
    private let clock: any AppClock
    private var startTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?

    public init(
        searchRepository: any SearchRepository,
        catalogRepository: any CatalogRepository,
        clock: any AppClock,
    ) {
        self.searchRepository = searchRepository
        self.catalogRepository = catalogRepository
        self.clock = clock
    }

    public func start() {
        guard state == .idle else {
            return
        }

        startTask?.cancel()
        startTask = Task {
            let categoriesResult = await catalogRepository.listCategories()
            if case .success(let outcome) = categoriesResult {
                var map: [CategorySlug: String] = [:]
                for category in outcome.value {
                    map[category.slug] = category.name
                }

                categoryNamesBySlug = map
            }
        }

        submitSearch()
    }

    public func onQueryTextChanged(_ newText: String) {
        queryText = newText
        suggestionTask?.cancel()

        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        suggestionTask = Task {
            do {
                try await clock.sleep(for: .milliseconds(Self.debounceMilliseconds))
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            let result = await searchRepository.suggestProducts(
                queryText: trimmed,
                limit: Self.suggestionLimit,
            )
            guard !Task.isCancelled else {
                return
            }

            if case .success(let items) = result {
                suggestions = items
            }
        }
    }

    public func pickSuggestion(_ suggestion: String) {
        suggestionTask?.cancel()
        suggestions = []
        queryText = suggestion
        submitSearch()
    }

    public func selectCategoryFacet(_ slug: CategorySlug?) {
        if selectedCategorySlug == slug {
            selectedCategorySlug = nil
        } else {
            selectedCategorySlug = slug
        }

        submitSearch()
    }

    public func selectSort(_ sort: SearchSortOption) {
        guard selectedSort != sort else {
            return
        }

        selectedSort = sort
        submitSearch()
    }

    public func submitSearch() {
        suggestionTask?.cancel()
        suggestions = []
        searchTask?.cancel()
        loadMoreTask?.cancel()
        isLoadingMore = false
        state = .searching

        let currentQuery = buildQuery(offset: 0)
        searchTask = Task {
            let result = await searchRepository.searchProducts(query: currentQuery)
            guard !Task.isCancelled else {
                return
            }

            switch result {
            case .failure(let failure):
                if failure != .cancelled {
                    state = .failed(failure)
                }
            case .success(let response):
                if response.hits.isEmpty {
                    state = .empty
                } else {
                    state = .results(response)
                }
            }
        }
    }

    public func loadNextPageIfNeeded(currentSku: ProductSku? = nil) {
        guard !isLoadingMore,
            case .results(let currentResponse) = state,
            currentResponse.hits.count < currentResponse.totalCount
        else {
            return
        }

        if let currentSku,
            let lastSku = currentResponse.hits.last?.sku,
            currentSku != lastSku
        {
            return
        }

        isLoadingMore = true
        let nextOffset = currentResponse.hits.count
        let nextQuery = buildQuery(offset: nextOffset)

        loadMoreTask?.cancel()
        loadMoreTask = Task {
            let result = await searchRepository.searchProducts(query: nextQuery)
            guard !Task.isCancelled else {
                isLoadingMore = false
                return
            }

            isLoadingMore = false
            if case .success(let nextResponse) = result {
                var existingSkus = Set(currentResponse.hits.map(\.sku))
                var combinedHits = currentResponse.hits
                for hit in nextResponse.hits where existingSkus.insert(hit.sku).inserted {
                    combinedHits.append(hit)
                }

                let merged = SearchResponse(
                    totalCount: nextResponse.totalCount,
                    hits: combinedHits,
                    categoryFacets: nextResponse.categoryFacets,
                    indexStatus: nextResponse.indexStatus,
                )
                state = .results(merged)
            }
        }
    }

    public func categoryDisplayName(for slug: CategorySlug) -> String {
        return categoryNamesBySlug[slug] ?? slug.value
    }

    private func buildQuery(offset: Int) -> SearchQuery {
        let categories: [CategorySlug]
        if let selectedCategorySlug {
            categories = [selectedCategorySlug]
        } else {
            categories = []
        }

        return SearchQuery(
            queryText: queryText,
            categorySlugs: categories,
            sort: selectedSort,
            limit: Self.defaultLimit,
            offset: offset,
        )
    }
}
