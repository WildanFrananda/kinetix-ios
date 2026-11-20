import SwiftUI

nonisolated struct KinetixLogoMark: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 32.0
        let scaleY = rect.height / 32.0

        var path = Path()
        path.move(to: CGPoint(x: 10.0 * scaleX, y: 7.0 * scaleY))
        path.addLine(to: CGPoint(x: 10.0 * scaleX, y: 25.0 * scaleY))
        path.move(to: CGPoint(x: 10.0 * scaleX, y: 16.0 * scaleY))
        path.addLine(to: CGPoint(x: 22.0 * scaleX, y: 7.5 * scaleY))
        path.move(to: CGPoint(x: 10.0 * scaleX, y: 16.0 * scaleY))
        path.addLine(to: CGPoint(x: 22.0 * scaleX, y: 24.5 * scaleY))

        return path
    }
}
