import Foundation
import KinetixDomain

public struct CatalogAPIClient: Sendable {
    private static let skuAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(
        CharacterSet(charactersIn: "/?#[]@!$&'()*+,;=")
    )

    private let apiCaller: SafeApiCaller

    public init(apiCaller: SafeApiCaller) {
        self.apiCaller = apiCaller
    }

    public func listCategories() async -> Result<[ProductCategory], Failure> {
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/categories",
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            return await Self.decodeCategories(from: response.body)
        }
    }

    public func listProducts(query: ProductListQuery) async -> Result<ProductPage, Failure> {
        var components = URLComponents()
        components.path = "/api/v1/products"
        var queryItems: [URLQueryItem] = []

        if let categorySlug = query.categorySlug {
            queryItems.append(URLQueryItem(name: "category", value: categorySlug.value))
        }

        if let searchText = query.searchText {
            queryItems.append(URLQueryItem(name: "q", value: searchText))
        }

        queryItems.append(URLQueryItem(name: "page", value: String(query.page)))
        queryItems.append(URLQueryItem(name: "page_size", value: String(query.pageSize)))
        components.queryItems = queryItems

        let path = components.string ?? "/api/v1/products"
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
            return await Self.decodeProductPage(from: response.body)
        }
    }

    public func getProduct(sku: ProductSku) async -> Result<ProductDetail, Failure> {
        let encodedSku =
            sku.value.addingPercentEncoding(withAllowedCharacters: Self.skuAllowedCharacters)
            ?? sku.value
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/products/\(encodedSku)",
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            return await Self.decodeProductDetail(from: response.body)
        }
    }

    @concurrent
    private static func decodeCategories(
        from data: Data
    ) async -> Result<[ProductCategory], Failure> {
        guard let dtos = try? JSONDecoder().decode([CategoryResponseDTO].self, from: data) else {
            return .failure(.unreadableResponse)
        }

        var categories: [ProductCategory] = []
        categories.reserveCapacity(dtos.count)

        for dto in dtos {
            guard let category = dto.toDomain() else {
                return .failure(.unreadableResponse)
            }

            categories.append(category)
        }

        return .success(categories)
    }

    @concurrent
    private static func decodeProductPage(from data: Data) async -> Result<ProductPage, Failure> {
        guard let dto = try? JSONDecoder().decode(ProductListResponseDTO.self, from: data),
            let page = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(page)
    }

    @concurrent
    private static func decodeProductDetail(
        from data: Data
    ) async -> Result<ProductDetail, Failure> {
        guard let dto = try? JSONDecoder().decode(ProductDetailResponseDTO.self, from: data),
            let detail = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(detail)
    }
}
