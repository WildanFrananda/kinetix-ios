import Foundation
import KinetixDomain

public struct SearchAPIClient: Sendable {
    private let apiCaller: SafeApiCaller

    public init(apiCaller: SafeApiCaller) {
        self.apiCaller = apiCaller
    }

    public func suggestProducts(
        queryText: String,
        limit: Int,
    ) async -> Result<[String], Failure> {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .success([])
        }

        var components = URLComponents()
        components.path = "/api/v1/products/suggest"
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: String(min(max(1, limit), 20))),
        ]

        let path = components.string ?? "/api/v1/products/suggest"
        let request = HTTPRequest(
            method: .get,
            path: path,
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let dto = try? JSONDecoder().decode(SuggestResponseDTO.self, from: response.body)
            else {
                return .failure(.unreadableResponse)
            }

            return .success(dto.suggestions)
        }
    }

    public func searchProducts(query: SearchQuery) async -> Result<SearchResponse, Failure> {
        var components = URLComponents()
        components.path = "/api/v1/products/search"
        var queryItems: [URLQueryItem] = []

        if let queryText = query.queryText {
            queryItems.append(URLQueryItem(name: "q", value: queryText))
        }

        for categorySlug in query.categorySlugs {
            queryItems.append(URLQueryItem(name: "category", value: categorySlug.value))
        }

        if let sort = query.sort, sort != .relevance {
            queryItems.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }

        queryItems.append(URLQueryItem(name: "limit", value: String(query.limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(query.offset)))
        components.queryItems = queryItems

        let path = components.string ?? "/api/v1/products/search"
        let request = HTTPRequest(
            method: .get,
            path: path,
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            return await Self.decodeSearchResponse(from: response.body)
        }
    }

    @concurrent
    private static func decodeSearchResponse(
        from data: Data
    ) async -> Result<SearchResponse, Failure> {
        guard let dto = try? JSONDecoder().decode(SearchResponseDTO.self, from: data),
            let domain = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(domain)
    }
}
