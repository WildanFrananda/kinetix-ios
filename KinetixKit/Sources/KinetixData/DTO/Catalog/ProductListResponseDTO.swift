import Foundation
import KinetixDomain

public struct ProductListResponseDTO: Codable, Sendable {
    public let count: Int
    public let page: Int
    public let pageSize: Int
    public let results: [ProductSummaryDTO]

    enum CodingKeys: String, CodingKey {
        case count = "count"
        case page = "page"
        case pageSize = "page_size"
        case results = "results"
    }

    public func toDomain() -> ProductPage? {
        var items: [ProductSummary] = []
        items.reserveCapacity(results.count)

        for dto in results {
            guard let item = dto.toDomain() else {
                return nil
            }

            items.append(item)
        }

        return ProductPage(
            totalCount: count,
            page: page,
            pageSize: pageSize,
            items: items,
        )
    }
}
