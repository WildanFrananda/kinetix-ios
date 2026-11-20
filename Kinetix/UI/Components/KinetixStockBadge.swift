import KinetixDomain
import SwiftUI

struct KinetixStockBadge: View {
    let status: StockStatus
    let availableQuantity: Int?

    init(
        status: StockStatus,
        availableQuantity: Int? = nil,
    ) {
        self.status = status
        self.availableQuantity = availableQuantity
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
                .accessibilityHidden(true)

            Text(labelResource)
                .font(KinetixTypography.caption)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(KinetixPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    foregroundColor.opacity(0.45),
                    lineWidth: KinetixTheme.borderWidthHairline,
                )
        )
    }

    private var iconName: String {
        switch status {
        case .inStock:
            return "checkmark.circle.fill"
        case .outOfStock:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .inStock:
            return KinetixPalette.successGreen
        case .outOfStock:
            return KinetixPalette.dangerRed
        case .unknown:
            return KinetixPalette.warningAmber
        }
    }

    private var labelResource: LocalizedStringResource {
        switch status {
        case .inStock:
            if let availableQuantity, availableQuantity > 0 {
                return .catalogStockAvailableCount(availableQuantity)
            }

            return .catalogStockInStock
        case .outOfStock:
            return .catalogStockOutOfStock
        case .unknown:
            return .catalogStockUnknown
        }
    }
}
