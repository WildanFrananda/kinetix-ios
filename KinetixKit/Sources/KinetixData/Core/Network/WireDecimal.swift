import Foundation

public enum WireDecimal {
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let allowedCharacters = CharacterSet(charactersIn: "0123456789.-")

    public static func parse(_ rawValue: String) -> Decimal? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return nil
        }

        let dotCount = trimmed.filter { $0 == "." }.count
        guard dotCount <= 1 else {
            return nil
        }

        let minusCount = trimmed.filter { $0 == "-" }.count
        if minusCount > 1 || (minusCount == 1 && !trimmed.hasPrefix("-")) {
            return nil
        }

        if trimmed == "-" || trimmed == "." || trimmed == "-." {
            return nil
        }

        guard let value = Decimal(string: trimmed, locale: posixLocale), !value.isNaN else {
            return nil
        }

        return value
    }

    public static func parseHTTPSURL(_ rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
            let components = URLComponents(string: trimmed),
            components.scheme?.lowercased() == "https",
            let host = components.host,
            !host.isEmpty
        else {
            return nil
        }

        return components.url
    }
}
