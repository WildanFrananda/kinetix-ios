import Foundation

public struct SearchResponse: Equatable, Hashable, Codable, Sendable {
    public let totalCount: Int
    public let hits: [SearchHit]
    public let categoryFacets: [SearchCategoryFacet]
    public let indexStatus: SearchIndexStatus

    public init(
        totalCount: Int,
        hits: [SearchHit],
        categoryFacets: [SearchCategoryFacet],
        indexStatus: SearchIndexStatus,
    ) {
        self.totalCount = totalCount
        self.hits = hits
        self.categoryFacets = categoryFacets
        self.indexStatus = indexStatus
    }
}
