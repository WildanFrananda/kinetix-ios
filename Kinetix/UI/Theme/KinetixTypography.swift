import SwiftUI

enum KinetixTypography {
    static let display = Font.system(.title, design: .default, weight: .bold)
    static let headline = Font.system(.title2, design: .default, weight: .bold)
    static let title = Font.system(.headline, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
    static let fieldLabel = Font.system(.footnote, design: .default, weight: .medium)
    static let eyebrow = Font.system(.caption, design: .default, weight: .semibold)
    static let labelMono = Font.system(.footnote, design: .monospaced, weight: .medium)
    static let otpCode = Font.system(.title, design: .monospaced, weight: .bold)
}
