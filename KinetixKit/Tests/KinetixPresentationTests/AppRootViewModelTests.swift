import Foundation
import KinetixDomain
import KinetixFakes
import KinetixPresentation
import Testing

struct AppRootViewModelTests {
    @Test
    func initializerIsInertAndStartsInValidatingState() {
        let source = FakeAppConfigSource(
            input: AppConfigInput(
                httpBase: "https://api.example.test",
                wsBase: "wss://api.example.test",
            )
        )
        let viewModel = AppRootViewModel(
            configSource: source,
            validator: AppConfigValidator(),
        )

        #expect(viewModel.state == .validating)
    }

    @Test
    func startTransitionsToConfiguredWhenValid() throws {
        let source = FakeAppConfigSource(
            input: AppConfigInput(
                httpBase: "https://api.example.test",
                wsBase: "wss://api.example.test",
            )
        )
        let viewModel = AppRootViewModel(
            configSource: source,
            validator: AppConfigValidator(),
        )

        viewModel.start()

        let expectedHTTP = try #require(URL(string: "https://api.example.test"))
        let expectedWS = try #require(URL(string: "wss://api.example.test"))
        #expect(
            viewModel.state
                == .configured(
                    AppConfig(
                        httpBaseURL: expectedHTTP,
                        wsBaseURL: expectedWS,
                    )
                )
        )
    }

    @Test
    func startTransitionsToInvalidConfigurationListingEveryBadKey() {
        let source = FakeAppConfigSource(
            input: AppConfigInput(httpBase: nil, wsBase: "ws://insecure.example.test")
        )
        let viewModel = AppRootViewModel(
            configSource: source,
            validator: AppConfigValidator(),
        )

        viewModel.start()

        #expect(
            viewModel.state
                == .invalidConfiguration([
                    AppConfigIssue(key: .httpBase, kind: .missing),
                    AppConfigIssue(key: .wsBase, kind: .malformed),
                ])
        )
    }
}
