import Foundation

public struct ApiErrorParser: Sendable {
    public init() {}

    public func parse(_ data: Data) -> ApiErrorEnvelope {
        guard !data.isEmpty else {
            return ApiErrorEnvelope()
        }

        guard
            let rawObject = try? JSONSerialization.jsonObject(with: data),
            let dict = rawObject as? [String: Any]
        else {
            return ApiErrorEnvelope()
        }

        let error = dict["error"] as? String
        let code = dict["code"] as? String
        let field = dict["field"] as? String
        let traceId = (dict["traceId"] as? String) ?? (dict["requestId"] as? String)

        let retryAfterSeconds: Int?
        if let intValue = dict["retryAfterSeconds"] as? Int {
            retryAfterSeconds = intValue
        } else if let doubleValue = dict["retryAfterSeconds"] as? Double {
            retryAfterSeconds = Int(doubleValue.rounded(.up))
        } else {
            retryAfterSeconds = nil
        }

        let messages: [String]
        if let singleMessage = dict["message"] as? String {
            messages = [singleMessage]
        } else if let arrayMessages = dict["message"] as? [String] {
            messages = arrayMessages
        } else {
            messages = []
        }

        let hasServiceFields =
            error != nil
            || code != nil
            || traceId != nil
            || dict["statusCode"] != nil
            || retryAfterSeconds != nil
        let isGatewayUnauthorizedOnly =
            !hasServiceFields
            && messages.count == 1
            && messages.first == "Unauthorized"

        return ApiErrorEnvelope(
            error: error,
            code: code,
            messages: messages,
            retryAfterSeconds: retryAfterSeconds,
            field: field,
            traceId: traceId,
            isServiceJSON: hasServiceFields && !isGatewayUnauthorizedOnly,
        )
    }
}
