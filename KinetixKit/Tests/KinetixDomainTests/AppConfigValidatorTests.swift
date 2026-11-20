import Foundation
import KinetixDomain
import Testing

struct AppConfigValidatorTests {
    private let validator = AppConfigValidator()

    @Test
    func acceptsValidHttpsAndWssBaseURLs() {
        let input = AppConfigInput(
            httpBase: "https://api.example.test",
            wsBase: "wss://api.example.test",
        )

        let result = validator.validate(input)

        switch result {
        case .success(let config):
            #expect(config.httpBaseURL.absoluteString == "https://api.example.test")
            #expect(config.wsBaseURL.absoluteString == "wss://api.example.test")
        case .failure(let error):
            Issue.record("Expected valid configuration, got \(error.issues)")
        }
    }

    @Test
    func reportsBothKeysMissingWhenNilOrBlankOrUnexpanded() {
        let cases: [AppConfigInput] = [
            AppConfigInput(httpBase: nil, wsBase: nil),
            AppConfigInput(httpBase: "   ", wsBase: "\n"),
            AppConfigInput(
                httpBase: "$(KINETIX_HTTP_BASE)",
                wsBase: "$(KINETIX_WS_BASE)",
            ),
        ]

        for input in cases {
            let result = validator.validate(input)
            #expect(
                result
                    == .failure(
                        AppConfigValidationError(
                            issues: [
                                AppConfigIssue(key: .httpBase, kind: .missing),
                                AppConfigIssue(key: .wsBase, kind: .missing),
                            ]
                        )
                    )
            )
        }
    }

    @Test
    func rejectsCleartextSchemesAndTruncatedXcconfigURLs() {
        let input = AppConfigInput(
            httpBase: "http://api.example.test",
            wsBase: "wss:",
        )

        let result = validator.validate(input)

        #expect(
            result
                == .failure(
                    AppConfigValidationError(
                        issues: [
                            AppConfigIssue(key: .httpBase, kind: .malformed),
                            AppConfigIssue(key: .wsBase, kind: .malformed),
                        ]
                    )
                )
        )
    }

    @Test
    func rejectsURLsWithQueryFragmentOrCredentials() {
        let inputs: [AppConfigInput] = [
            AppConfigInput(
                httpBase: "https://api.example.test?debug=1",
                wsBase: "wss://api.example.test",
            ),
            AppConfigInput(
                httpBase: "https://api.example.test",
                wsBase: "wss://api.example.test#frag",
            ),
            AppConfigInput(
                httpBase: "https://user:pass@api.example.test",
                wsBase: "wss://api.example.test",
            ),
        ]

        for input in inputs {
            let result = validator.validate(input)
            switch result {
            case .success:
                Issue.record("Expected malformed configuration failure")
            case .failure(let error):
                #expect(error.issues.count == 1)
                #expect(error.issues.first?.kind == .malformed)
            }
        }
    }
}
