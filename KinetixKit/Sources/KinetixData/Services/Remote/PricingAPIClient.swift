import Foundation
import KinetixDomain

public struct PricingAPIClient: Sendable {
    private static let skuAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(
        CharacterSet(charactersIn: "/?#[]@!$&'()*+,;=")
    )

    private let apiCaller: SafeApiCaller

    public init(apiCaller: SafeApiCaller) {
        self.apiCaller = apiCaller
    }

    public func listDiscounts() async -> Result<[PromotionDiscount], Failure> {
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/pricing/discounts",
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            return await Self.decodeDiscounts(from: response.body)
        }
    }

    public func getFlashSale(productSku: ProductSku) async -> Result<FlashSale?, Failure> {
        let encodedSku =
            productSku.value.addingPercentEncoding(
                withAllowedCharacters: Self.skuAllowedCharacters
            )
            ?? productSku.value
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/pricing/flash-sales/\(encodedSku)",
            isWrite: false,
            requiresAuth: false,
        )

        let result = await apiCaller.execute(request)
        switch result {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            return await Self.decodeFlashSale(from: response.body)
        }
    }

    @concurrent
    private static func decodeDiscounts(
        from data: Data
    ) async -> Result<[PromotionDiscount], Failure> {
        guard let dtos = try? JSONDecoder().decode([DiscountResponseDTO].self, from: data) else {
            return .failure(.unreadableResponse)
        }

        var discounts: [PromotionDiscount] = []
        discounts.reserveCapacity(dtos.count)

        for dto in dtos {
            guard let discount = dto.toDomain() else {
                return .failure(.unreadableResponse)
            }

            discounts.append(discount)
        }

        return .success(discounts)
    }

    @concurrent
    private static func decodeFlashSale(from data: Data) async -> Result<FlashSale?, Failure> {
        let rawText = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if rawText == "null" {
            return .success(nil)
        }

        guard let dto = try? JSONDecoder().decode(FlashSaleResponseDTO.self, from: data),
            let flashSale = dto.toDomain()
        else {
            return .failure(.unreadableResponse)
        }

        return .success(flashSale)
    }
}
