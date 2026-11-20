import Foundation
import KinetixDomain

public struct SearchResponseDTO: Codable, Sendable {
    public let total: Int
    public let hits: [SearchHitDTO]
    public let facets: SearchFacetsDTO?
    public let index: SearchIndexDTO

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case hits = "hits"
        case facets = "facets"
        case index = "index"
    }

    public func toDomain() -> SearchResponse? {
        var mappedHits: [SearchHit] = []
        mappedHits.reserveCapacity(hits.count)

        for dto in hits {
            guard let hit = dto.toDomain() else {
                return nil
            }

            mappedHits.append(hit)
        }

        var categoryFacets: [SearchCategoryFacet] = []
        if let rawBuckets = facets?.categories {
            for bucket in rawBuckets {
                if let mapped = bucket.toCategoryFacet() {
                    categoryFacets.append(mapped)
                }
            }
        }

        return SearchResponse(
            totalCount: total,
            hits: mappedHits,
            categoryFacets: categoryFacets,
            indexStatus: index.toDomain(),
        )
    }
}
