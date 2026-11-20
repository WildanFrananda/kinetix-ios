import Foundation

public enum SearchSortOption: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case relevance = "relevance"
    case priceAscending = "price_asc"
    case priceDescending = "price_desc"
    case newest = "updated_desc"
}
