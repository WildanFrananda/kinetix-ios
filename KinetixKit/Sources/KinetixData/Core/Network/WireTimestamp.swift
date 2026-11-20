import Foundation

public struct WireTimestamp: Sendable {
    public static func parseRFC3339(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let normalized = normalizeFractionalSeconds(trimmed)
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]
        if let date = fractionalFormatter.date(from: normalized) {
            return date
        }

        let wholeFormatter = ISO8601DateFormatter()
        wholeFormatter.formatOptions = [.withInternetDateTime]
        return wholeFormatter.date(from: normalized)
    }

    private static func normalizeFractionalSeconds(_ input: String) -> String {
        guard let dotIndex = input.firstIndex(of: ".") else {
            return input
        }

        let afterDot = input.index(after: dotIndex)
        var fractionEnd = afterDot
        while fractionEnd < input.endIndex && input[fractionEnd].isNumber {
            fractionEnd = input.index(after: fractionEnd)
        }

        let fractionDigits = String(input[afterDot..<fractionEnd])
        guard !fractionDigits.isEmpty && fractionDigits.count <= 9 else {
            return input
        }

        let prefix = String(input[..<afterDot])
        let suffix = String(input[fractionEnd...])
        let normalizedFraction: String
        if fractionDigits.count > 3 {
            normalizedFraction = String(fractionDigits.prefix(3))
        } else {
            normalizedFraction = fractionDigits.padding(
                toLength: 3,
                withPad: "0",
                startingAt: 0,
            )
        }

        return prefix + normalizedFraction + suffix
    }
}
