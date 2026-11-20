import Foundation
import KinetixDomain

public struct ReviewAPIClient: Sendable {
    private static let skuAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(
        CharacterSet(charactersIn: "/?#[]@!$&'()*+,;=")
    )

    private let apiCaller: SafeApiCaller

    public init(apiCaller: SafeApiCaller) {
        self.apiCaller = apiCaller
    }

    public func listProductReviews(
        productSku: ProductSku,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        let encodedSku =
            productSku.value.addingPercentEncoding(
                withAllowedCharacters: Self.skuAllowedCharacters
            )
            ?? productSku.value
        let clampedPage = max(1, page)

        var components = URLComponents()
        components.path = "/api/v1/reviews/products/\(encodedSku)"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(clampedPage))
        ]

        let path = components.string ?? "/api/v1/reviews/products/\(encodedSku)"
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
            return await Self.decodeProductReviews(from: response.body)
        }
    }

    public func listMerchantReviews(
        merchantPrincipalId: PrincipalId,
        page: Int,
    ) async -> Result<ReviewPage, Failure> {
        let clampedPage = max(1, page)

        var components = URLComponents()
        components.path = "/api/v1/reviews/merchants/\(merchantPrincipalId.value)"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(clampedPage))
        ]

        let path = components.string ?? "/api/v1/reviews/merchants/\(merchantPrincipalId.value)"
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
            return await Self.decodeMerchantReviews(from: response.body)
        }
    }

    @concurrent
    private static func decodeProductReviews(
        from data: Data
    ) async -> Result<ReviewPage, Failure> {
        guard let dto = try? JSONDecoder().decode(ProductReviewsResponseDTO.self, from: data),
            let page = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(page)
    }

    @concurrent
    private static func decodeMerchantReviews(
        from data: Data
    ) async -> Result<ReviewPage, Failure> {
        guard let dto = try? JSONDecoder().decode(MerchantReviewsResponseDTO.self, from: data),
            let page = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(page)
    }
}
