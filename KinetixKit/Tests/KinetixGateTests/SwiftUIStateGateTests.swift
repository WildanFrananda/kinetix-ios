import Foundation
import Testing

struct SwiftUIStateGateTests {
    @Test
    func appAndPresentationFollowSwiftUIAndStateRules() throws {
        let root = try RepositoryLocator.repositoryRoot()
        let files = try RepositoryLocator.swiftFiles(in: root)
        var violations: [String] = []

        for file in files {
            let isProductionFile =
                file.relativePath.hasPrefix("Kinetix/")
                || file.relativePath.hasPrefix("KinetixKit/Sources/")
            guard isProductionFile else {
                continue
            }

            violations.append(
                contentsOf: Self.checkFile(
                    relativePath: file.relativePath,
                    contents: file.contents,
                )
            )
        }

        #expect(
            violations.isEmpty,
            "SwiftUI/state violations: \(violations.joined(separator: "; "))",
        )
    }

    @Test
    func checkerRejectsAnyViewStringNavigationAndUserFacingTextInViewModel() {
        let anyViewSource = """
            struct BadView {
                var body: AnyView { AnyView(EmptyView()) }
            }
            """
        #expect(
            !Self.checkFile(
                relativePath: "Kinetix/UI/Screens/Auth/BadView.swift",
                contents: anyViewSource,
            ).isEmpty
        )

        let stringRoute = """
            struct BadNav {
                func make() {
                    let _ = navigationDestination(for: String.self) { _ in EmptyView() }
                }
            }
            """
        #expect(
            !Self.checkFile(
                relativePath: "Kinetix/App/BadNav.swift",
                contents: stringRoute,
            ).isEmpty
        )
    }

    static func checkFile(
        relativePath: String,
        contents: String,
    ) -> [String] {
        var violations: [String] = []
        let stripped = SwiftSourceScanner.stripStringLiterals(from: contents)

        if stripped.contains("AnyView") {
            violations.append("\(relativePath): AnyView is forbidden")
        }

        if stripped.contains("navigationDestination(for: String.self)") {
            violations.append("\(relativePath): string route navigation is forbidden")
        }

        if relativePath.contains("/ViewModels/") {
            if stripped.contains("LocalizedStringResource")
                || stripped.contains("LocalizedStringKey")
            {
                violations.append(
                    "\(relativePath): ViewModels expose Failure values, never localized text"
                )
            }
        }

        return violations
    }
}
