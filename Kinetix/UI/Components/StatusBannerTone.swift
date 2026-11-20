import SwiftUI

enum StatusBannerTone {
    case danger
    case warning
    case success
    case info

    var foregroundColor: Color {
        switch self {
        case .danger:
            return KinetixPalette.dangerRed
        case .warning:
            return KinetixPalette.warningAmber
        case .success:
            return KinetixPalette.successGreen
        case .info:
            return KinetixPalette.infoBlue
        }
    }

    var systemImage: String {
        switch self {
        case .danger:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "clock.badge.exclamationmark.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}
