import Foundation

enum KinetixPriceFormatter {
    static func format(
        amount: Decimal,
        currency: String,
        locale: Locale = .autoupdatingCurrent,
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let nsNumber = NSDecimalNumber(decimal: amount)
        let formattedNumber = formatter.string(from: nsNumber) ?? "\(amount)"
        let trimmedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCurrency.isEmpty {
            return formattedNumber
        }

        return "\(trimmedCurrency) \(formattedNumber)"
    }
}
