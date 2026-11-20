# AGENTS.md — Kinetix Buyer iOS Application (`kinetix-ios`)

`AGENTS.md` and `CLAUDE.md` in this repository are one document kept as two byte-identical files, so every coding agent loads the same contract. Edit `AGENTS.md`, copy it over `CLAUDE.md`, and prove it: `cmp AGENTS.md CLAUDE.md` prints nothing.

This is the system design, architectural contract, coding standard, gate specification, backend contract digest, phased plan and decisions log for **`kinetix-ios`**: the customer-facing native iOS application of Kinetix (display name **`Kinetix`**, bundle identifier **`com.kinetix.shop`**), the sibling of `kinetix-android`.

The estate forbids comments in source code, so every design decision, protocol invariant and failure classification lives here and in test names. The file is longer than one tool read returns: read it to the end, in as many reads as that takes. §0 comes first on purpose.

**Authority.** The user in chat; then this file; then the workspace `CONTEXT.md`; then an agent memory note. For what the backend does, a service's source wins, then the published reference built from it (`kinetix-docs`, §4), then this file: where they disagree this file is stale, so stop and correct it before writing Swift. For how the gateway behaves, its live configuration (`kinetix-api-gateway/config/envoy/`) wins over the published page, which still describes the previous engine.

**Provenance.** Written 2026-11-19 from files that were read, then reviewed the same day by four reviewers (backend contracts twice, the Apple platform against the installed toolchain, the estate's rules), with every blocker and major finding re-derived by a second reader before it changed this text. Where it matters a claim names its basis: *read* (from a file), *verified* (run or type-checked on this machine), *judgment*.

---

## 0. State and log — read first

### 0.1 Where the repository stands

Measured 2026-11-20. **Phase 0 (including GitHub Actions CI/CD, Dependabot, CodeRabbit, and PR template) and Phase 1 are built and green (iOS 18.0 simulator runtime testing and IOS-D13 Apple Developer signing remain owed).**

| Fact | Value |
| :--- | :--- |
| Toolchain | Xcode 27.2 (27B52), Swift 6.4.2, the toolchain's own `swift-format` 6.4.4 |
| Simulator | iOS 27.2 (24B8117) is the only runtime; 5 iPhone and 6 iPad devices exist for it. **No runtime of the minimum iOS (IOS-D1) is installed**, so nothing can run on it yet |
| Project file | `Kinetix.xcodeproj/project.xcproj`: Xcode 27's JSON-like text format. There is no `project.pbxproj`. `xcrun xcprojformatter` prints the file canonically and drops keys it does not know |
| Source membership | `Kinetix/`, `KinetixTests/` and `KinetixUITests/` are synchronized folders: every file inside one is a member of its target, with no project edit |
| Targets | `Kinetix` (app), `KinetixTests` (Swift Testing, hosted by the app), `KinetixUITests` (XCTest UI); local package `KinetixKit` (`KinetixDomain`, `KinetixData`, `KinetixPresentation`, `KinetixFakes`, 4 test targets); one auto-created scheme `Kinetix`; default configuration is Release |
| Bundle identifier | `com.kinetix.shop` (`com.kinetix.shop.tests`, `com.kinetix.shop.uitests`) |
| Deployment target | iOS 18.0 in project settings (`KinetixTests` override removed) |
| Language mode | `SWIFT_VERSION = 6.0`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target only), `SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT = YES`, `SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` |
| Device family | `1` (iPhone only), portrait only, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`, `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO` |
| Configuration | `Configuration/App.xcconfig` (`#include? "Local.xcconfig"`) on both Debug and Release; `Configuration/Info.plist` merged with `GENERATE_INFOPLIST_FILE = YES` |
| Strings | `Kinetix/Resources/Localizable.xcstrings` in English (`en`) and Indonesian (`id`), symbol generation on |
| Built | Phase 0 (configuration, package, theme, gate, `bin/ci`) and Phase 1 (transport, Keychain session & single-flight renewer, auth/2FA/profile repositories, SwiftData Cache + Ledger/Outbox with IOS-D5 tripwire, `AppRouter`, auth/2FA/profile/account screens, local crash & analytics adapters, rules 7 & 10 gates) |
| Git and signing | git repository initialized (`main` branch); no team (IOS-D13 is deferred) |

Two consequences bind every agent:

- **`project.pbxproj` knowledge and tools do not apply.** Change a project setting through Xcode, or by editing `project.xcproj` as text while Xcode does not hold the project open. After a change made through Xcode, read the diff to learn the shape. Never guess a key.
- **Xcode 27, Swift 6.4 and iOS 27 are newer than most agents' training data.** Anything introduced after iOS 18 / Swift 6.0 is read from the installed toolchain (`swift --version`, `xcodebuild -showBuildSettings`, the SDK's `.swiftinterface` files, Xcode's documentation window), never recalled. The spellings this file gives were verified on this machine on the date beside them.

### 0.2 Log

Append after every completed step or decision; newest last.

**2026-11-19 — Project created, design written.** The user created the Xcode project (`Kinetix`, SwiftUI, Swift Testing with XCTest UI tests, SwiftData storage); its folder was renamed to `kinetix-ios` at the user's request. This file was written. No Swift was changed.

**2026-11-19 — The user ruled.** IOS-D1 (iOS 18.0), D6 (Firebase Messaging, Crashlytics, Analytics, Remote Config), D7 (iPhone only, portrait), D8 (`kinetix-android`'s tokens, dark only), D9 (multilingual buyer copy on both buyer apps), D12 (GitHub Actions; `xtool` considered, not adopted), D14 (a signing page owned by `kinetix-docs`). D13 is deferred: the estate runs on free tooling for now. D9 and D14 were also appended to `kinetix-android`'s log.

**2026-11-19 — Reviewed and corrected.** 3 blocker and 30 major findings, all confirmed by a second reader, changed this file. The ones that would have produced wrong code:
- Contracts: the cart voucher body is `{ voucherCode }`, not `{ code }`; timestamps and money have no single wire format; the error envelope differs per service; disabling 2FA needs a code; the top-up body, statuses and its own `502`; checkout is classified by error code and by whose body it is, not by status; nullable stock fields; the tracking frame's nullable fields and the token the edge keeps; `issuedAt` is Unix seconds as a string; forgetting a handset needs a JSON body.
- Gateway: the limits published for the old engine do not hold. Budgets are shared by all callers, a gateway `429` has no `Retry-After`, and the wait is 15 seconds (§1.6).
- Design: every stored row has an owner; an unfinished checkout is never replayed without the buyer (IOS-D17); protected data can be unreadable on a background launch; nested `@Model` classes are required for migrations; nonisolated async functions run on the caller's actor; ports have local adapters before Firebase arrives; previews carry no domain data (IOS-D18); no backend kill switch exists.
- Verified that day (*read* at their production tags): edge v1.4.0, notification v1.3.3, matching v1.6.0, notary v1.10.1, order v1.6.1, review v1.4.1, gateway v2.2.0, identity v1.7.3. The published reference still pins older releases for the gateway, identity, order, review and seal (§7 Q15).
- Not verified: Envoy was not run (its behaviour is read from configuration and Envoy's documented defaults); no Swift was built beyond type-checks and small experiments in a scratch directory; nothing ran on iOS 18; Firebase SDK behaviour; whether a refused WebSocket upgrade exposes its status.

**2026-11-20 — Phase 0 built and verified.**
- Cleaned the Xcode template (`Item.swift`, sample `ContentView`, SwiftData `fatalError`, header comments, placeholder unit test, UI launch-performance test) and moved `Assets.xcassets` under `Kinetix/Resources/`.
- Added `.gitignore`, `.xcode-version` (`27.2`), `.swift-format`, `Configuration/App.xcconfig`, `Configuration/Local.xcconfig.example`, `Configuration/Info.plist`, and `bin/ci`.
- Created local Swift package `KinetixKit/` (`swift-tools-version: 6.4`, `.iOS(.v18)`, `.macOS(.v15)`) with `KinetixDomain`, `KinetixData`, `KinetixPresentation`, `KinetixFakes` (`Tests/KinetixFakes`), and 4 test targets (`KinetixDomainTests`, `KinetixDataTests`, `KinetixPresentationTests`, `KinetixGateTests`).
- Verified `project.xcproj` canonical shape via `xcrun xcprojformatter --update` and `xcodebuild`:
  - Base xcconfig: `"configurations": [{ "name": "Debug", "file": "Configuration/App.xcconfig" }, { "name": "Release", "file": "Configuration/App.xcconfig" }]`, matching a `"Configuration"` group in `"files"` whose children are `App.xcconfig`, `Info.plist`, and `Local.xcconfig.example`.
  - Local package: `"packages": [{ "kind": "local", "path": "KinetixKit" }]`, linked per target via `"package-product-members": [{ "package": "KinetixKit", "product-name": "<Product>", "build-phase": { "build-phase": "frameworks" } }]`.
- Verified `Kinetix` app compile line in the `xcodebuild` log carries `-swift-version 6`, `-default-isolation=MainActor`, `-enable-upcoming-feature NonisolatedNonsendingByDefault`, `-enable-upcoming-feature InferIsolatedConformances`, `-enable-upcoming-feature MemberImportVisibility`, `-warnings-as-errors`, and `-target arm64-apple-ios18.0-simulator`.
- Implemented Phase 0 startup slice: `AppConfig`, `AppConfigKey`, `AppConfigIssueKind`, `AppConfigIssue`, `AppConfigValidationError`, `AppConfigInput`, `AppConfigSource`, `AppConfigValidator` (`KinetixDomain`), `BundleAppConfigSource` (`KinetixData`), `AppStartupState` and `AppRootViewModel` (`KinetixPresentation`), `KinetixPalette`/`KinetixTypography`/`KinetixTheme` matching `kinetix-android` dark tokens, `ConfigErrorContent`/`ConfigErrorScreen`, `AppContainer`, `AppRootScreen`, `KinetixApp`, and `Localizable.xcstrings` (`en` + `id`).
- Gates seen red before green: `ZeroCommentsGateTests` (caught template comments across 5 files), `ConcurrencyGateTests` (caught `fatalError(` in template `KinetixApp.swift`), `HouseLayoutGateTests` (caught compact closing braces in `ContentView.swift` and `DtoAndConfigGateTests.swift`), `swift-format lint --strict` (caught 13 line-length/trailing-comma errors), `--explicit-target-dependency-import-check error` + `LayerAndImportGateTests` (caught deliberate undeclared `import KinetixData` in `KinetixPresentation`), plus negative unit tests for rules 3, 4, 5, 6, 8 and 9.
- Gate run (`bin/ci`, all 5 steps green): `cmp AGENTS.md CLAUDE.md` OK; `swift-format lint --strict` 0 errors; `swift test --package-path KinetixKit --explicit-target-dependency-import-check error` on macOS 27.2 passed **22 tests in 9 suites** (`KinetixDomainTests` 4, `KinetixDataTests` 2, `KinetixPresentationTests` 3, `KinetixGateTests` 13); `xcodebuild test -only-testing:KinetixTests` on iPhone 18 Pro Simulator (iOS 27.2) passed **2 tests in 1 suite**; Release simulator build succeeded with warnings as errors.
- Still owed from Phase 0: GitHub Actions workflow (waits on the user creating the git repository and GitHub remote, rule 15) and running `KinetixTests` on an iOS 18.0 simulator runtime once installed.

**2026-11-20 — Phase 1 built and verified.**
- Read all four Phase 1 buyer-app contract pages (`sign-up-and-sign-in.mdx`, `stay-signed-in.mdx`, `two-factor.mdx`, `profile.mdx`), all 11 endpoint specs in `kinetix-docs/src/site/rest/endpoints/identity.ts`, and `kinetix-identity-service` profile DTO/entity/usecase source.
- Built `KinetixDomain` Phase 1 core: `AppClock`, typed `Failure` enum with per-payload structs, validating typed IDs (`AccountId`, `PrincipalId`, `IdempotencyKey`), Auth/2FA/Profile models (`ProfilePatch` with field-level diffing and `AvatarUpdate` preserving `avatarUrl: null`), ports (`CrashReporter`, `AnalyticsTracker`, `ProtectedDataStatusProvider`, `RoutePersistenceStore`), and `Result`-returning repository protocols (`SessionRepository`, `AuthRepository`, `TwoFactorRepository`, `ProfileRepository`).
- Built `KinetixData` transport, session, stores, outbox, and repositories: ephemeral `URLSessionHTTPTransport` with per-task `URLSessionTaskMetricsDelegate` (`requestLeftDevice` rule), `ApiErrorParser`, `WireTimestamp` (RFC 3339 0–9 fractional digits), `HttpFailureMapper`, `SafeApiCaller`, `KeychainSessionVault` (`SecItemAdd` + `SecItemUpdate`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, `.unreadable` vs `.signedOut`), `FirstLaunchSessionCleaner` (protected-data guarded), `TokenRefreshTransport` (3 refresh outcomes), single-flight `SessionRenewer` actor, explicit-`CodingKeys` Auth/2FA/Profile DTOs (`UpdateProfileRequestDTO` omitting unchanged fields and encoding `null` only for `avatarUrl` removal), separate SwiftData Cache & Ledger containers (`CacheSchemaV1`, `LedgerSchemaV1`, nested `@Model` classes, `@ModelActor` background actors, backup-excluded directories), principal-isolated `OutboxProcessor` (15s–300s backoff + `Retry-After` + `"outbox_entry_synced"`), `IdentityAPIClient`, and all four repository implementations.
- Built `KinetixPresentation` (`AppRoute`, `AppRouter` with per-principal persistence, updated `AppRootViewModel`, `SignInViewModel`, `RegisterViewModel`, `TwoFactorChallengeViewModel`, `TwoFactorSettingsViewModel`, `ProfileViewModel`, `AccountHomeViewModel`) and `Kinetix` app UI (local OSLog crash/analytics adapters, `UIKitProtectedDataStatusProvider`, `FailureMessageMapper`, reusable dark components, on-device `QRCodeImageView`, `AppDelegateAdaptor` registering `BGAppRefreshTask`, all Phase 1 `XScreen` + stateless `XContent` views, and full `en` + `id` String Catalog entries).
- Extended `KinetixGateTests` to Rules 7 (`FailureHandlingGateTests`) and 10 (`SwiftUIStateGateTests`), each with negative control unit tests; `HouseLayoutGateTests` and `swift-format lint --strict` caught real layout/formatting issues before turning green.
- IOS-D5 SwiftData tripwire proven on both macOS 27.2 (`SwiftDataTripwireTests`: persistence across containers, `#Unique` upsert preserving `attemptCount`, V1→V2 lightweight migration preserving rows, off-main-thread `@ModelActor`) and iPhone 18 Pro Simulator iOS 27.2 (`SwiftDataIOSTripwireTests`). Testing on an iOS 18.0 simulator runtime remains owed until that runtime is installed.
- Gate run (`bin/ci`, all 5 steps green): `cmp AGENTS.md CLAUDE.md` OK; `swift-format lint --strict` 0 errors; `swift test --package-path KinetixKit --explicit-target-dependency-import-check error` on macOS 27.2 passed **57 tests in 21 suites** (`KinetixDomainTests` 9 in 3 suites, `KinetixDataTests` 22 in 7 suites, `KinetixPresentationTests` 9 in 3 suites, `KinetixGateTests` 17 in 8 suites); `xcodebuild test -only-testing:KinetixTests` on iPhone 18 Pro Simulator (iOS 27.2) passed **5 tests in 4 suites** (`KinetixTests`, `FailureMessageMapperTests`, `KeychainSessionVaultTests`, `SwiftDataIOSTripwireTests`); Release simulator build succeeded with warnings as errors.

**2026-11-20 — Phase 1 UI redesign & Simulator visual verification (`ios-design` + `ui-taste`).**
- Established image-first visual targets for Sign In and Delivery Profile locked strictly to `KinetixPalette` dark tokens, a 2-radius shape scale (`cornerRadiusControl = 10`, `cornerRadiusCard = 14`), zero gradients/glow/glass/pill buttons, sans-serif form labels (reserving monospace for OTP codes, manual 2FA keys, and config keys), and single primary Electric Volt accent.
- Added `KinetixLogoMark`, `KinetixBrandHeader`, `KinetixSectionHeader`, `KinetixGroupedInputRow`, `KinetixPressButtonStyle`, and focus/tab enums (`AuthFormField`, `TwoFactorSettingsTab`, `ProfileFormField`); upgraded `KinetixTextField` (placeholders, Electric Volt focus ring, password visibility toggle, `SubmitLabel` keyboard chaining) and `KinetixPrimaryButton` (Reduce Motion-aware press feedback and muted-Volt disabled styling).
- Redesigned all Phase 1 screens (`SignInContent`, `RegisterContent` with live password rule checklist, `TwoFactorChallengeContent` with prominent monospaced OTP entry, `TwoFactorSettingsContent` with Enable/Disable segmented picker & one-tap copy secret, `ProfileContent` with grouped CONTACT / ADDRESS 2-column City+Postal / AVATAR cards & docked Save bar, `AccountHomeContent` with monogram header, grouped rows & Sign Out confirmation dialog, and `ConfigErrorContent`) and expanded `Localizable.xcstrings` (`en` + `id`).
- Verified visually on iPhone 18 Pro Simulator (iOS 27.2) via `xcrun simctl io screenshot` (`sim_signin.png` → refined logo proportion, disabled CTA visual anchor, dark navigation bar chrome → re-verified `sim_signin_v2.png`); note that authenticated screens (`AccountHome`, `Profile`, `TwoFactorSettings`) were verified via SwiftUI build/gates and preview compilation, not yet captured interactively against a signed-in session.
- Gate run (`bin/ci`, all 5 steps green): `cmp AGENTS.md CLAUDE.md` OK; `swift-format lint --strict` 0 errors; `KinetixKit` on macOS 27.2 passed **57 tests in 21 suites**; `KinetixTests` on iPhone 18 Pro Simulator (iOS 27.2) passed **5 tests in 4 suites**; Release simulator build succeeded with warnings as errors.

**2026-11-20 — User ruled (IOS-D8 amended): adopt `kinetix-docs` palette & brand mark.**
- User ruled that `kinetix-ios` must match `kinetix-docs`'s canonical warm-dark palette (`kinetix-docs/src/styles/kx-tokens.css` + `landing.css`) rather than `kinetix-android`'s earlier Obsidian/Electric Volt tokens.
- Updated `KinetixPalette` (`background` `#131210`, `surface` `#191815`, `surfaceElevated` `#1F1D1A`, `accent` `#F0742F`, `accentLow` `#3B1E0F`, `accentHigh` `#FFC9A6`, `textPrimary` `#F6F2EA`, `textSecondary` `#CFC9BD`, `textTertiary` `#969083`, `textMuted` `#5D584F`, `tileLight` `#F3EFE7`, `infoBlue` `#74A9D6`, `successGreen` `#74C29D`, `warningAmber` `#FFB377`, `dangerRed` `#E85D4F`, `borderHairline` `#34312C`, `borderStrong` `#4A463F`), `Assets.xcassets/AccentColor` (`#F0742F`), `KinetixLogoMark` + `KinetixBrandHeader` (matching `kinetix-docs/src/assets/kinetix-mark-dark.svg`), and all Phase 1 components and screens.
- Visually verified the updated palette and brand mark on iPhone 18 Pro Simulator (iOS 27.2) against a live signed-in session (`AccountHomeContent` captured via `xcrun simctl io screenshot`).
- Gate run (`bin/ci`, all 5 steps green): `cmp AGENTS.md CLAUDE.md` OK; `swift-format lint --strict` 0 errors; `KinetixKit` on macOS 27.2 passed **57 tests in 21 suites** (`KinetixDomainTests` 9 in 3 suites, `KinetixDataTests` 22 in 7 suites, `KinetixPresentationTests` 9 in 3 suites, `KinetixGateTests` 17 in 8 suites); `KinetixTests` on iPhone 18 Pro Simulator (iOS 27.2) passed **5 tests in 4 suites**; Release simulator build succeeded with warnings as errors.

**2026-11-20 — CI/CD and repository automation configured (IOS-D12, IOS-D15).**
- Confirmed from GitHub `actions/runner-images` (`xcode-27-arm64-Readme.md`) that the GA `xcode-27` Apple Silicon runner includes Xcode 27.2 at `/Applications/Xcode_27.2.app`.
- Extended `bin/ci` with optional `--package-only` and `--simulator-only` modes plus `KINETIX_XCRESULT_DIR` support while keeping plain `./bin/ci` as the single local and CI entry point running all 5 steps.
- Added `.github/workflows/ci.yml` (`package-and-lint` on `xcode-27`, `simulator-and-release-build` on `xcode-27` gated on `package-and-lint`, `security` Trivy critical vulnerability scan + SPDX SBOM on `ubuntu-latest`, and aggregating `verify` check), `.github/workflows/release.yml` (tag-triggered `v*.*.*` with `release-preflight` checking `KINETIX_HTTP_BASE`/`KINETIX_WS_BASE`, IOS-D13 signing secrets, and `Kinetix/GoogleService-Info.plist` `BUNDLE_ID == com.kinetix.shop`, Trivy + SBOM, `./bin/ci`, plain `xcodebuild archive` + `-exportArchive` upload via App Store Connect API key, and GitHub Release publication), `.github/dependabot.yml` (`swift` under `/KinetixKit` and `github-actions` targeting `development`), `.coderabbit.yaml` (assertive review instructions enforcing `AGENTS.md`), and `.github/PULL_REQUEST_TEMPLATE.md`. No `.gitlab-ci.yml` was added (IOS-D12).
- Validated YAML syntax on all four YAML files, `bash -n bin/ci`, and xcconfig URL escaping (`https:/$()/...`); ran `./bin/ci --package-only` and `./bin/ci --simulator-only` cleanly. Note: remote execution on GitHub Actions `xcode-27` runners will be verified once pushed to GitHub; `release.yml` archive/upload remains blocked on IOS-D13 signing secrets.

### 0.3 Owed

- **By the user:** IOS-D13 when push or distribution is wanted; installing an iOS 18 simulator runtime so the minimum can be tested (IOS-D1); creating the git repository and the GitHub remote (rule 15); overruling IOS-D17 or IOS-D18 if wanted.
- **By owning services:** §7 Q1–Q15.
- **In the workspace:** a `kinetix-ios` row in `CONTEXT.md` §2.3 and §2.4 and a section in the root `AGENTS.md` (the same is missing for `kinetix-android`); a brief in `kinetix-docs-internal/PLAN.md` for the operations page of §7 Q6. Not written on 2026-11-19: the root `AGENTS.md` is the user's text and another session's edit was open in the docs repository.

---

## 1. System design

### 1.1 Where the app sits

```text
+--------------------------- Kinetix for iOS (com.kinetix.shop) ---------------------------+
|  SwiftUI views -> view models -> repositories -> services (HTTP, socket, stores, Keychain) |
+--------+--------------------------------+-----------------------------------+-------------+
         | HTTPS, Bearer JWT              | WSS, Bearer JWT                   ^ APNs
         v                                v                                   |
+--------------- api.wildanfrananda.my.id, 443, TLS only ----------------+    |
|  kinetix-api-gateway (Envoy)                                            |   Firebase Cloud
|    /api/v1/...    -> identity, catalog, search, pricing, order,         |   Messaging
|                      payment, review, notary, notification              |    ^
|    /ws/v1/events  -> kinetix-edge-service (unified event socket)        |    |
+------------------------------+------------------------------------------+   kinetix-notification-service
                               | Redis Pub/Sub (courier positions)             (FCM HTTP v1)
                    kinetix-matching-service
```

- One public host serves the API: `https://api.wildanfrananda.my.id` under `/api/v1/`, and the event socket at `wss://api.wildanfrananda.my.id/ws/v1/events`. Port 80 is closed. *(read: `kinetix-docs`, `apis/rest/index.mdx`)*
- The gateway engine has been Envoy since 2026-11-14; the published reference still says Kong. A gateway answer is classified by its status and headers, never by its body (§1.6).

### 1.2 Boundaries the app never crosses

- **One door for the API.** Every call the app's own code makes to Kinetix goes to the configured API host over TLS: no gRPC, no broker, no database. Three kinds of traffic leave by other doors and are named here: images, fetched from the absolute `https` URL an answer carried, on whatever host that is (an empty or non-`https` `image_url` is no image, never a decoding failure); the Firebase SDK's and Apple's own traffic; and chat, when it ships, as MQTT over TLS to EMQX (§4.12).
- **The backend owns every business rule and every authoritative state**: the price paid, stock, wallet balance, voucher grants, order status. The app shows indications and server answers. It never derives a number the buyer is charged.
- **A client, not a coordinator.** The app never stitches two services into a transaction. A capability that is missing is built in its owning service first and recorded in §7; it is never approximated here.
- **Unknown is never a business answer.** "We could not ask" stays its own state all the way to the screen.
- **No feature ahead of its backend.** No mock screen, no sample data, no placeholder route.
- **No secret in the binary or the repository.**

### 1.3 Layers and modules

Hexagonal, as everywhere in the estate, with the layer vocabulary of `kinetix-android` and **no UseCase layer**: view models depend on repository protocols directly, as both sibling apps do.

```text
Kinetix (app target)        SwiftUI screens and components, theme, navigation host,
   |                        composition root, platform and Firebase adapters, String Catalog
   | imports all three
   v
KinetixPresentation         @Observable view models, UI state enums, routes        Foundation + Observation
KinetixData                 DTOs, HTTP transport, session, stores, outbox,         Foundation + system frameworks
   |                        event socket, repository implementations
   | both import only
   v
KinetixDomain               models, typed ids, Failure, repository protocols, ports      Foundation only
```

The three are targets of **one local Swift package, `KinetixKit/`** (IOS-D2), which declares `.iOS(.v18)` and `.macOS(.v15)`:

1. **Tests without a simulator.** `swift test` runs every domain, data and view-model test natively on the Mac. On a 16 GB laptop the simulator is the most expensive thing in the loop. What only iOS has (the Keychain's accessibility classes, UIKit, BackgroundTasks) is tested in the app's own test target, and the stores are tested in both places (§3.2).
2. **The dependency direction is declared in `Package.swift` and gated.** SwiftPM does not by default refuse an undeclared import of a sibling module, and any target can `import SwiftUI` without declaring it *(both verified)*, so the import allow-list of rule 6 is the enforcement.
3. **Isolation defaults per layer** (§1.4).

Dependencies are injected through initialisers. `AppContainer` in the app target is the **one hand-wired composition root**: no DI container, no service locator, no `static let shared` outside it.

### 1.4 Concurrency

- **Swift 6 language mode in every target; warnings are errors.**
- **Isolation.** The app target and `KinetixPresentation` default to `MainActor`. `KinetixDomain` and `KinetixData` default to nonisolated: values that cross a boundary are `Sendable` structs and enums, and shared mutable state lives in an actor (`SessionRenewer`, `OutboxProcessor`, `EdgeEventSocket`, each store's model actor) or, for synchronous state, in a `Mutex` (`Synchronization`).
- **A nonisolated async function runs on its caller's actor.** Every target enables the approachable-concurrency features, so a repository method awaited by a view model runs on the main actor between its suspension points. `nonisolated` is not a way off the main actor. Work that must leave the caller's actor (decoding a large page, mapping DTOs, hashing, decoding an image) is a function marked `@concurrent`, or lives in an actor.
- **Spellings verified on Swift 6.4.2, 2026-11-19:**
  - App target: Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, and, stated explicitly because Xcode applies `SWIFT_APPROACHABLE_CONCURRENCY` to language modes 4, 4.2 and 5 only, `SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT = YES` and `SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES = YES`.
  - Package targets: `.swiftLanguageMode(.v6)`, `.enableUpcomingFeature("ApproachableConcurrency")` (what `swift package init` itself writes; it turns on both features), `.enableUpcomingFeature("MemberImportVisibility")`, `.treatAllWarnings(as: .error)`, and `.defaultIsolation(MainActor.self)` on `KinetixPresentation` and its test target only.
  - The compiler accepts an unknown feature name in silence. Phase 0 confirms in the first build log that the app's compile line carries `-enable-upcoming-feature NonisolatedNonsendingByDefault` and the main-actor default, and records it in §0.2.
- **Structured concurrency first.** Screen work starts from `.task` / `.task(id:)`. An unstructured `Task` is allowed in three places only, each owned, stored and cancellable: an action the buyer triggers (started in the view model, which cancels the one it supersedes); the named actors' own work (the refresh in flight, the outbox drain, the socket's receive loop); a system callback that has no async form. None is fire-and-forget.
- **Forbidden:** `Task.detached`, `DispatchQueue`, `@unchecked Sendable`, `nonisolated(unsafe)`, Combine, completion-handler APIs of our own, `ObservableObject`, `@Published`, `@EnvironmentObject`. `@preconcurrency import` is allowed only under `Kinetix/Adapters/Firebase/`.
- **Time is a port.** Countdowns, backoff and polling read an injected clock, so tests never sleep.

### 1.5 Screens, state and navigation

- One screen is one `View`, one `@Observable` view model and one UI-state enum, each in its own file. The view renders the state with an exhaustive `switch` (no `default` over our own enums).
- The view owns its view model in `@State`; the composition root builds it and passes it through the initialiser. `@Bindable` only for form fields. `@Environment` carries SwiftUI-scoped values, never a service.

```swift
struct SignInScreen: View {
    @State private var viewModel: SignInViewModel

    init(viewModel: SignInViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SignInContent(state: viewModel.state, onSubmit: viewModel.submit)
    }
}
```

- SwiftUI builds a screen value many times and keeps only the first view model, so **a view model's initialiser stores its dependencies and its initial state and does nothing else**: no task, no subscription, no clock, no I/O. `submit()` is synchronous and starts the one task the view model owns.
- **A view model loads once.** `.task` calls `start()`, which does nothing when content is already held; a reload is an explicit `refresh()`. A request cancelled because the screen was covered leaves the held content in place. (`kinetix-android` had to fix exactly this reload on back navigation.)
- A screen is split into `XScreen` and a stateless `XContent(state:actions…)`. A `#Preview` may render `XContent` only in states that carry no domain data: loading, empty, each failure (IOS-D18). A product title, a price or an order number in a preview is sample data in the production tree and is forbidden.
- `AppRoute` and every UI-state enum are declared `nonisolated` and `Sendable`: they are values, usable from any isolation. View models and `AppRouter` stay on the main actor.
- Navigation is a `NavigationStack` bound to a typed path: `AppRoute` (`Hashable`, `Codable`) and `AppRouter` (the observable owner of `[AppRoute]`). No string routes, no placeholder route. A route never carries a credential or a token. A route that needs a session keeps its target while the buyer signs in, then resumes. The path is stored per scene, restored after process death for the same principal only, filtered at start (a route that needs a session waits behind sign-in or is dropped), and deleted when the session is cleared.
- View models expose typed `Failure` values, never text. The app target's `FailureMessageMapper` turns a failure into a String Catalog entry; all copy is referenced through the catalog's generated symbols.

### 1.6 Networking and the classification of failure

- `HTTPTransport` (a protocol in `KinetixData`) over a `URLSession` built from the ephemeral configuration with `urlCache = nil`, `requestCachePolicy = .reloadIgnoringLocalCacheData`, no cookie storage, `httpShouldSetCookies = false` and no credential storage; a test pins those five. The only cache is the Cache store of §1.8.
- Every request carries `Accept: application/json` and **`X-Request-Id`** (a fresh UUID), kept as a breadcrumb. `Authorization: Bearer` and `Idempotency-Key` only where §4 says. No `X-Kinetix-Client` today (§7 Q5). No `traceparent`: no service reads it. Never send `Content-Type: application/json` with an empty body: identity answers `400`.
- **Three types may catch a transport error or read a status:** `SafeApiCaller`, `TokenRefreshTransport`, and `EdgeEventSocket` for its handshake and frames. All map through `HttpFailureMapper`; none repeats the table. Repositories never catch `URLError`.
- **Expected failure is a value.** Repositories return `Result<Value, Failure>` and never throw to a view model. `Failure` is one `enum`; a case that carries fields takes a struct declared in its own file.

| What happened | Classified as | Never as |
| :--- | :--- | :--- |
| No route, DNS failure, connection refused, TLS failure | network failure, not sent | a refusal |
| Timeout or connection lost after the request left | outcome unknown | success or refusal |
| `502`, `503`, `504` whose body is **not** the service's JSON error (the gateway's) | outcome unknown on a write, unavailable on a read | a refusal, empty, zero |
| A service's own JSON error | what §4 says for that code | a generic failure |
| `429` | wait `Retry-After` when present, else `x-ratelimit-reset` seconds when present, else a named default of 60 s | a wrong password |
| `401` on a route whose contract has a `401` of its own (`login`, `2fa/verify`, `refresh`, the three 2FA management routes, `logout`) | that endpoint's answer | session expired |
| `401` on any other route | renew once (§1.7) whatever the local clock says, repeat once; a second `401` is session over | the endpoint's answer |
| A `2xx` the DTO cannot decode | unreadable answer | a default value |
| Task cancelled | cancelled, shown nowhere | an error banner |

- **Error bodies differ by service as much as keys do.** `ApiErrorParser` is tolerant: it reads an optional `error` string, an optional `code` string and an optional `message` that is a string or an array of strings, and treats an empty or non-JSON body as no code. A code is matched only where §4 names it.
  - identity, catalog, pricing: `{ error: CODE, message, traceId }` (catalog adds `field`). identity's framework refusals are `{ message, error: <HTTP reason phrase>, statusCode, traceId }`: there `error` is not a code, a wrong password has none, and a validation `message` is an array.
  - search: `{ error: <snake_case code> }`; its `404` is plain text.
  - order: `{ error: CODE, message, … }` with extra fields per code; `traceId` only on `500 INTERNAL_ERROR` and `503 DATABASE_UNAVAILABLE`; `application/problem+json` for a body it cannot bind; an empty body on its token `401`s and unknown-path `404`.
  - payment: `{ error: <sentence> }`; its machine code is `code`, never `error`.
  - gateway: `{ message: "Unauthorized" }` on `401`, plain text on `429`, `503`, `504`.
- **DTOs** use Swift-cased properties and always declare `CodingKeys`, so every wire name is written once and can be found by search. identity, order and payment answer camelCase; catalog, search, pricing, review and notification answer snake_case: a global key strategy is forbidden. A required field has no default; a field the contract allows to be `null` or absent is optional. An enumerated wire value the app does not know maps to an `unknown` case, never to a decoding failure.
- **Money is never `Double`, and only search's `price_minor` is an integer.** *(read from the services)* catalog `price` and pricing `value`, `flash_price`, `min_spend`, `max_discount` are decimal strings in rupiah with two decimals (`"89000.00"`; pricing's `value` is a percentage when `discount_type` is `PERCENTAGE`); pricing's request field `cart_subtotal` is sent as a decimal string. Order and cart amounts and payment's balances and amounts are JSON numbers in rupiah with up to two decimals (`85000`, `202000.00`); payment's `limit` on a `422` is a string. Search's `price_minor` is an integer of minor units (rupiah × 100), for ordering only. Decode each into `Decimal` (`Int64` for `price_minor`); a test proves that `193800.55`, `202000.00` and `85000` decode from JSON numbers exactly, on the minimum OS too.
- **Timestamps are not uniform; each field takes its shape from its endpoint's sample.** Most are RFC 3339 in UTC with zero to nine fractional digits, and the same field can arrive with or without a fraction. One `WireTimestamp` parser accepts all of them, and a table test pins `2026-11-16T03:18:05Z`, `2026-10-27T03:15:00.274Z`, `2026-10-22T03:25:00.481236Z` and `2026-10-22T03:15:07.4829137Z`, each seen red. Search sends epoch milliseconds as integers. Payment's `instructions.expiresAt` is not an instant: it is Midtrans' own text (`2026-10-23 10:15:00`, no zone), nullable, kept as a string, shown as received and never used for arithmetic (§7 Q12). The notary's `issuedAt` is Unix seconds as a decimal string (§4.10).
- **The gateway as it runs today** *(read: `kinetix-api-gateway/config/envoy/Filters.pkl`, `Routes.pkl`; Envoy was not run)*:
  - Each route has **one budget of 100 requests a minute shared by every caller**, not one per address. The budgets are: `login`, `register`, `refresh`, `2fa/verify` (one each), the rest of `/api/v1/auth`, `/api/v1/users`, `/api/v1/products/search`, `/api/v1/products/suggest`, `/api/v1/products`, `/api/v1/categories`, `/api/v1/pricing`, `/api/v1/cart`, `/api/v1/orders`, `/api/v1/reviews`, `/api/v1/payment`, three under `/api/v1/proofs`, `/api/v1/notifications/devices`, `/ws/v1/events`. A gateway `429` is therefore an ordinary event and never the buyer's fault.
  - The gateway adds no `Retry-After` to its `429`; a service's own `429` (identity's) does.
  - API routes set no timeout, so the gateway waits Envoy's default **15 seconds** for a service and then answers `504`. A slow write (a profile `PUT` that places an address, a checkout) can end in a gateway `504` while the service finishes.
  - Envoy answers `503`, not `502`, both when it cannot connect and when the upstream connection resets after the request was delivered.
  - identity also throttles its auth routes per client address (5 a minute on `login`, `register`, `2fa/verify` and the 2FA management routes); read the others on the endpoint.
  - Polling and retry intervals are named constants with a test, never literals in a view model.

### 1.7 Session and secure storage

- The whole session (`accessToken`, `refreshToken`, expiry instant, `accountId`, `principalId`, `email`, `role`) is **one Keychain generic-password item holding one encoded value**, replaced in a single write: `SecItemAdd`, then `SecItemUpdate` on `errSecDuplicateItem`, never delete-then-add. Accessibility is `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Tokens never touch `UserDefaults`, SwiftData, a file or a log.
- **Could-not-read is not no-session.** A Keychain status other than success or `errSecItemNotFound`, `errSecInteractionNotAllowed` in particular, means the session is unknown: nothing is cleared, nothing is sent, the work waits for the next activation. Before the first unlock after a restart the Keychain item, `UserDefaults` and both stores are all unreadable, and iOS does launch the app in that state (a push, a background refresh, prewarming).
- A Keychain item outlives the app's deletion, so a stale one is deleted on the first launch of an install. That decision is taken only on a foreground activation with protected data available (read through a port the app target implements) and the `UserDefaults` marker absent. A background launch never takes it: an unreadable marker looks absent.
- **`SessionRenewer` is an actor and single-flight.** Callers that find the token expired await the one refresh in flight; the in-flight task is recorded before the first suspension. The token is renewed when 60 seconds or less remain (a named constant). On `200` both tokens are written before any caller resumes. The session is never renewed from a background launch.
- **A refresh token is never sent twice** (identity treats a spent one sent again as theft and ends the session family). So the outcome of a refresh is one of three:

| Outcome | When | Then |
| :--- | :--- | :--- |
| Refused | `400`, `401`, `403` | the session is cleared; sign in |
| Not spent | the request never left the device; `429`; identity's own `503 DATABASE_UNAVAILABLE`; a gateway `502` or `503` | the session is kept; try later |
| Unknown | the request left and no readable answer came back; `500`; `504`; an unreadable `2xx`; any other status | the session is cleared; sign in |

  Keeping the session on a gateway `502`/`503` follows both sibling apps. Under Envoy such a `503` can follow a refresh identity did process; the later attempt is then answered `401` and the session ends there (§7 Q11).
- **"Left the device" is read, not guessed**: it left if any element of the task's `URLSessionTaskMetrics.transactionMetrics` has `countOfRequestHeaderBytesSent > 0` or a non-nil `requestStartDate`; it did not if every element has neither; if no metrics were delivered the answer is unknown and counts as left. The metrics come from a per-task delegate.
- The access-token lifetime is read from `expiresIn` on every answer; it is never a constant in code.
- No app extension reads the session. Adding one changes this design (an access group, a single-flight across processes): record that decision here first.

### 1.8 Local persistence: a disposable cache and a durable ledger

Two SwiftData stores with different promises, reached only through `KinetixData` (no `@Model` type and no `@Query` ever reaches a view). Each is its own `ModelContainer` with its own `VersionedSchema`, `SchemaMigrationPlan`, explicit store URL and `cloudKitDatabase: .none`, in its own directory under Application Support; the directory is excluded from backup and its file protection still allows a background flush.

| Store | Holds | Promise |
| :--- | :--- | :--- |
| **Cache** | categories, product pages and details (public), the delivery profile (owned) | Disposable. Written through on every successful read; served only when the network fails, and labelled as possibly out of date. If it cannot be opened or migrated it is deleted and rebuilt |
| **Ledger** | pending transaction states and outbox entries | Durable. Saved explicitly **before** the request it protects is sent. Never deleted to recover from an error |

- **A pending transaction state holds the key and the exact request body.** Order and payment both tie an `Idempotency-Key` to the body it was first sent with, so a repeat must send the same bytes of meaning: for a checkout `shippingAddress`, `recipientName`, `recipientPhone`, `shippingServiceTier`, `voucherCode` (a field that was absent stays absent); for a top-up `amount`, `paymentMethod`, `bank` and, once known, its `referenceNumber`, until it leaves `PENDING`. The ledger therefore holds a name, a phone number and an address: it stays out of logs.
- **Every row has an owner.** Each ledger row and outbox entry carries the `PrincipalId` of the buyer who created it, and the cached profile is keyed by `AccountId`; the public catalogue cache has no owner. Reads, repeats and drains take only the rows of the signed-in principal: a row of another principal is never sent and never shown. Order and payment deduplicate per buyer, so a key repeated under another buyer's token is a new charge, not a repeat. When the session is cleared, that principal's cached profile and stored navigation path are deleted; its ledger and outbox rows stay until the same principal signs in again. (`kinetix-courier-mobile` shipped the unowned version and sent one courier's queue as another's.)
- **Protected data.** A store that cannot be opened while protected data is unavailable is neither a ledger fault nor a reason to delete the cache: the app waits and opens it then. With protected data available, a ledger that cannot be opened is a fault: the app does not crash and does not start with an empty one; checkout and top-up are refused with a stated reason (a single charge cannot be guaranteed), everything else keeps working, and the fault is reported.
- **Schemas.** Each version is an enum conforming to `VersionedSchema` (`LedgerSchemaV1`, `CacheSchemaV1`) with its `@Model` classes nested inside it. SwiftData gives `@Model` no entity name of its own, so two versions of a model keep their rows across a migration only by sharing a class name; top-level `OutboxEntryV1` / `OutboxEntryV2` are different entities and a lightweight stage between them silently drops every row *(verified on macOS 27.2)*. The current version of a model is reached through one top-level `typealias` in a file named after the model. A released version is frozen; a change is a new version plus a stage in the plan.
- **Uniqueness is an upsert.** The dedupe key is declared with `#Unique`. A collision does not throw: at save the stored row takes the inserted values. Where that would lose state (an attempt count, an entry isolated as failed) the outbox fetches by key before it inserts.
- **Outbox.** Only writes the contract makes safe to repeat and that have no screen waiting on a server answer go through it: the delivery profile `PUT`, and reviews and courier ratings.
  - The profile has one entry per principal. A later edit is **merged** into it, so the entry always holds every field changed since the last profile identity confirmed (the newer value wins per field; `avatarUrl: null` survives a merge). Diffing is against the last confirmed profile, never the optimistic one.
  - An entry ends in one of three ways. **Done:** a `2xx`, and a `409` for a review or rating, whose `review_id` is kept. **Later:** not sent, a timeout, `429`, `500`, `502`–`504`, a `409` on the profile `PUT` (created concurrently: read it, then send), and a `401` after one renewal. **Refused:** any other `4xx`; the entry is isolated as permanently failed and reported.
  - Backoff starts at 15 s, doubles to 300 s and honours `Retry-After`. The UI says "saved on this device, not sent yet" for as long as that is true.
- **Never through the outbox:** checkout and top-up (online only, protected by the ledger), and every cart write. `POST /api/v1/cart/items` adds to a quantity, so a blind repeat can double it: an unknown outcome there is settled by reading the cart. The cart writes that are safe to repeat stay out too: a cart shown while a write waits would differ from the cart checkout prices.
- iOS gives no background guarantee. The outbox drains on enqueue, on becoming active, when the network returns, and opportunistically from a `BGAppRefreshTask`.
- **SwiftData is the engine by IOS-D5, which carries a tripwire.** Phase 1 must prove, with tests seen red: a save that survives a new container on the same file; the unique key's upsert; a migration that preserves ledger rows; and that store work runs off the main thread. A pass under `swift test` proves macOS's SwiftData only: the same suites run on an iOS simulator (§3.2), and IOS-D5 is not satisfied for the minimum OS until they have run on an iOS 18 runtime. If any cannot be proven, the ledger moves to SQLite and this section is rewritten before Phase 3.

### 1.9 Realtime: the edge event socket

- One `EdgeEventSocket` actor over `URLSessionWebSocketTask`, owned by the composition root, multiplexing subscriptions. Its only consumer today is live courier tracking (§4.8).
- **Open only while** a tracking screen is visible, the scene is active and the order's `status` is `PAID` or `PROCESSING_FULFILLMENT`. It closes on backgrounding, at sign-out (the edge never closes it) and when an order read shows another status. On return the app reads the order over REST first, then reconnects and subscribes again. Reconnects use exponential backoff with jitter.
- **A silent subscription is normal.** Positions flow only while matching holds the delivery assigned or picked up, which no REST answer tells a buyer (§7 Q13). The screen has its own state for "subscribed, no courier position yet" and never shows it as an error.
- **The edge checks the access token once, at the handshake, and keeps it for the life of the connection** *(read: `event_socket.tl`, v1.4.0)*. It never re-verifies and never closes on expiry, sign-out or revocation; subscriptions already acknowledged keep delivering. Every later `subscription.subscribe` is authorised by reading the order with that handshake token; once order refuses it as expired, the edge answers `command.error` `UPSTREAM_UNAVAILABLE` with `retryable: true`, the same frame as a real outage. So the socket remembers the `exp` of the token it connected with: before a subscribe at or after that instant it closes, renews (§1.7), reconnects and subscribes. `UPSTREAM_UNAVAILABLE` on a connection whose token is still in date is retried with backoff; `retryable` alone is never followed blindly.
- **Handshake.** The request carries `Authorization: Bearer`; no subprotocol, no query token. A refused upgrade is classified by status: `401 SESSION_ENDED` renew once then retry; `401 SESSION_REQUIRED` is our own bug (no Bearer header) and is reported, not retried; `429` carries no `Retry-After` here, so the reconnect backoff applies; `502`/`503` back off. *(Unverified: that `task.response` carries the status of a refused upgrade. Phase 4 proves it against a refusing server for 401, 426, 429, 502 and 503 before relying on it.)*
- **Liveness is any inbound frame.** `system.ping` every 25–30 s keeps inside the edge's 60 s receive timeout. The edge answers one client frame at a time, so while a subscribe awaits its ack a pong can be late by as long as the order read takes: a missing `system.pong` counts only when no command is awaiting its ack, against a named deadline with a test.
- A position is last-write-wins: the envelope's `sequence` is `null` on position frames, so drop a frame whose `data.recordedAt` is older than the one shown, and drop a repeated `eventId`. The socket is a view of the present, never a store.
- The map is MapKit (IOS-D10).

### 1.10 Push notifications

- The notification service sends through **FCM HTTP v1 only** and accepts `platform` `ANDROID` or `IOS`; the address it stores is an **FCM registration token**. The app therefore uses the Firebase Messaging SDK over APNs. Method swizzling is off (`FirebaseAppDelegateProxyEnabled = NO`); the app delegate adaptor forwards the APNs token and incoming messages explicitly.
- **What is needed, and from whom:**

| Capability | Declaration | Needs |
| :--- | :--- | :--- |
| An APNs token (and so an FCM token) | Push Notifications capability: `aps-environment` in `Configuration/Kinetix.entitlements` | IOS-D13 (a paid membership) |
| The silent ownership challenge | `UIBackgroundModes` contains `remote-notification` | nothing more |
| The outbox refresh | `UIBackgroundModes` contains `fetch`; `BGTaskSchedulerPermittedIdentifiers` lists the one identifier; the handler is registered before launch ends | nothing more; cannot be scheduled in Simulator |

- `registerForRemoteNotifications` runs at every launch and does not wait for the permission prompt: the token, the registration of §4.11 and the silent challenge need no permission. The prompt governs visible alerts only.
- **While IOS-D13 is deferred there is no push entitlement**, so APNs registration fails. That is rendered as "push unavailable", never as an error the buyer must act on.
- **The handset is registered** whenever a session and an FCM token are both present and that pair has not been registered in this run: at a start with a session, right after a sign-in or sign-up, and when the SDK replaces the token.
- **The ownership challenge reaches iOS as a background push** (`apns-push-type: background`, priority 5, `content-available: 1`). It is handled in `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` only if the stored access token is still valid: with an expired token, an unreadable Keychain or no network the message is dropped and the next foreground start registers again. iOS delivers such a push at once to a foreground app, the normal case right after sign-in; in the background it is best-effort and never reaches an app the user force-quit.
- **What a buyer can receive today is one notification**: the notary's liability statement, the only template any caller is granted in production. The order templates exist and no service sends them. A visible notification carries a title and a body, rendered by the server in Indonesian, and no data. So a tap opens the app where it was and refreshes the visible screen; it never routes by guess (§7 Q3, Q10).
- The permission prompt is asked in context, never at first launch: from notification settings, or from the proofs screen, the one feature that sends a push today. Asking after an order waits until order sends notifications.

### 1.11 Lifecycle and background execution

iOS suspends the app at will; the design assumes nothing runs in the background.

| Moment | What the app does |
| :--- | :--- |
| Process launch, foreground or background | validate configuration (§1.12); set the delegates; register the background task handler; nothing that reads the session or a store |
| First activation with protected data available | the first-launch decision (§1.7); restore the session and check it with `GET /api/v1/auth/me`; register the handset (§1.10); drain the outbox of the signed-in principal; show an unfinished checkout or top-up of that principal from the ledger |
| Becomes active | renew the session if due; drain the outbox; refresh the visible screen; reopen the event socket if a tracking screen is showing |
| Enters background | close the event socket; stop polling; ask for brief extra time only to finish a write already in flight; schedule the refresh task if the outbox is not empty |
| Background push | handle a `DEVICE_VERIFICATION` message as §1.10 says, or drop it |
| Killed mid-checkout or mid-top-up | at the next start the app sends nothing by itself (IOS-D17). A top-up that already has a `referenceNumber` is followed by reading its status. A checkout or top-up whose key has no final answer is shown to the buyer as unfinished (what, when, to which address) after the cart and page 1 of the orders are read, and the buyer chooses: finish it (the same request, body and `Idempotency-Key`, so an attempt that reached the service is answered from its record) or drop it (the row is closed and its key is never used again) |

The customer app never requests background location and never keeps a socket alive in the background.

### 1.12 Configuration and environments

- Two build configurations, Debug and Release. There is no staging estate: a build points at production or at a developer's lab. There are no mock services.
- Two values are injected at build time and have **no default anywhere**: `KINETIX_HTTP_BASE` (must start with `https://`) and `KINETIX_WS_BASE` (must start with `wss://`). `Configuration/App.xcconfig` is the base configuration of both build configurations and contains `#include? "Local.xcconfig"`: the optional form, so a missing file is not a build error; the values are then empty and `ConfigErrorScreen` names them. `Local.xcconfig` is untracked; `Local.xcconfig.example` is tracked; CI writes the file from repository variables.
- In an `.xcconfig` file `//` starts a comment even inside a value, which silently cuts a URL to its scheme. A URL is written with an empty expansion between the slashes:

```text
KINETIX_HTTP_BASE = https:/$()/api.wildanfrananda.my.id
KINETIX_WS_BASE = wss:/$()/api.wildanfrananda.my.id
```

- `Configuration/Info.plist` sits outside the synchronized folders (a target's Info.plist must not also be its resource), with `INFOPLIST_FILE` pointing at it and `GENERATE_INFOPLIST_FILE` kept. It holds only what has no `INFOPLIST_KEY_` build setting: the two configuration keys, `UIBackgroundModes`, `BGTaskSchedulerPermittedIdentifiers`, `FirebaseAppDelegateProxyEnabled`.
- `AppConfigValidator` runs before the first screen. A missing or malformed value renders `ConfigErrorScreen` naming every bad key at once, never a value, instead of starting navigation.
- App Transport Security stays at its default; no exception key is ever added. A lab reached from the simulator is reached over TLS with the lab's CA installed in the simulator (§7 Q6).
- `GoogleService-Info.plist` is untracked and, when present, sits inside `Kinetix/`, where the synchronized folder bundles it. The Firebase adapters bind when it is in the bundle. Without it both configurations still build, so `bin/ci` is green on a machine that has none, and the app runs with the local adapters of §1.13 and without push, saying so once in the log. Only the release workflow refuses: its `release-preflight` step will not archive unless the plist for `com.kinetix.shop` is in the bundle. This follows `kinetix-android` and is a recorded departure from the estate's fail-fast rule and from `kinetix-courier-mobile`; the user may overrule it. The file at the workspace root belongs to `com.kinetix.courier` and must never be used here.

### 1.13 Observability

- **Correlation** is by `X-Request-Id`: the gateway returns it and services repeat it in error bodies (`traceId`, `requestId`).
- **Logging.** `Logger` (OSLog) with privacy annotations. Never logged: tokens, email, phone, address, names, a request body. Logged: the route template, the status, the request id, the failure case.
- **Crashes, analytics and flags are ports** in `KinetixDomain` (`CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`), each with two production adapters in the app target. `Kinetix/Adapters/Local/` holds `OSLogCrashReporter`, `OSLogAnalyticsTracker` and `BundledFeatureFlagProvider`: they are the behaviour of a build without Firebase, not fakes, and arrive with their first callers. `Kinetix/Adapters/Firebase/` holds the Firebase adapters of Phase 4, the only files that import Firebase (IOS-D6).
- **Flags.** Feature keys are shared with `kinetix-android`, read from its `remote_config_defaults.xml`: `checkout_enabled`, `wallet_topup_enabled`, `live_tracking_enabled`, `outbox_sync_enabled`. Version gates (`minimum_supported_version_code`, `force_update_enabled`) are per platform; the iOS keys are agreed with whoever owns the console before they are read. A flag that cannot be fetched takes its bundled default, the one Android bundles. **No backend kill switch exists today**: it is the edge's case X8, planned and not built, so the app's flag is the only switch and cannot reach a build that has not fetched it. A flag never replaces a server answer.
- **Analytics** uses the event names `kinetix-android` already sends; read them there before adding one.
- **Device metrics.** MetricKit diagnostics go to the crash reporter; signposts mark app start and first content. Budgets are set after the first measurement on a real device.

### 1.14 Security posture

- Session in the Keychain (§1.7); the ledger holds a delivery address and a phone number and is treated accordingly (§1.8).
- TLS only, default ATS, no pinning.
- Authorization is the server's. After every session answer the app reads `role`: only a `customer` is a buyer account for the wallet (§4.1).
- Passwords are never stored: the 2FA management screens ask each time, as the contract requires.
- A proof document is kept and exported byte for byte as received; it is never decoded and re-encoded.
- Anything that comes back from outside the process (a pasted or scanned signature, a restored route, a push payload) is checked for shape before use.
- App integrity is deferred: production does not enforce it. When it does, the app names itself in `X-Kinetix-Client` and sends a Firebase App Check token (App Attest on iOS) in `X-Firebase-AppCheck` on the calls that issue or renew tokens (§7 Q5).
- Associated domains (Universal Links, AutoFill association, passkeys) need a file served on a host that serves none today, and IOS-D13 (§7 Q4).

### 1.15 Design system, accessibility and localisation

- Brand palette and mark follow `kinetix-docs` (IOS-D8, amended 2026-11-20 by the user): the dark colour tokens are read from `kinetix-docs/src/styles/kx-tokens.css` (warm dark `#131210` canvas, `#191815` / `#1F1D1A` surfaces, `#34312C` / `#4A463F` rules, `#F6F2EA` / `#CFC9BD` / `#969083` warm text scale, `#F0742F` / `#3B1E0F` / `#FFC9A6` terracotta accent scale, `#74A9D6` / `#74C29D` semantic lanes) and the brand mark matches `kinetix-docs/src/assets/kinetix-mark-dark.svg`, declared in Swift under `UI/Theme/`; the app is dark only.
- The estate's taste binds here too: no gradients, no glow, no glass effects of our own, no pill buttons, hairline borders, restraint.
- System typography with Dynamic Type; a monospaced face for prices, codes and identifiers. No price is truncated at the accessibility sizes.
- Every interactive element has a 44-point target and a VoiceOver label; state is never conveyed by colour alone; Reduce Motion is honoured.
- Buyer copy is multilingual on both buyer apps (IOS-D9): English is the development language of the String Catalog, and Indonesian (`id`) is added to it as each phase's copy settles. Code, identifiers, tests and this file stay English.

### 1.16 Performance

- Lists are paged by the server and rendered lazily; a view model never holds a whole catalogue.
- Images go through one pipeline (IOS-D11): decoding off the main actor, downsampling to the displayed size, memory and disk caches, cancellation when a cell leaves the screen.
- Identical in-flight reads are coalesced in the repository, not in the view.
- Performance claims are measured on a device with Instruments and written into §0.2 with the number.

---

## 2. Non-negotiable rules

A rule marked **(Gate)** is enforced by `KinetixGateTests` once its phase lands the check **and §0.2 records it seen red**. Until then it is a review rule.

1. **The estate's rules bind here.** Read the workspace `CONTEXT.md` §1 and §2 before the first change and §8 before any claim to the user. Never publish anything from this repository as a web artifact. Never print a secret value to chat, a log or a command's arguments, and never open `GoogleService-Info.plist`, `Configuration/Local.xcconfig` or a signing or API key file to quote from it. Never invent an identifier, a host, a key name, a build setting or any other value: if it was not read from a file, a command's output or the user, it does not exist.
2. **English only.** Swift, identifiers, test names, file names, commit messages and every Markdown file here. Buyer-facing copy in another language lives only in the String Catalog.
3. **Zero comments in source (Gate).** No `//`, `/* */`, `///`, `// MARK:`, no commented-out code in `.swift` files; the scanner is literal-aware (a URL inside a string is not a comment). The one exception is the tool directive that opens `Package.swift`. In `.xcconfig` files any `//` is a violation, without exception.
4. **House layout (`CONTEXT.md` §2.1), every file.**
   - An opening brace stays on the line that opens it.
   - Too long for one line: every element on its own line, a trailing comma, the closing bracket alone. A call that fits stays on one line.
   - Blank lines between contexts: after a closing brace before the next statement, before a `return` that ends a longer block, between groups of statements that do different things. An assignment stays with the check that reads it. No blank line just inside a brace.
   - The formatter is configured to this style, never the reverse. It can express braces, one argument per line, trailing commas and no blank line inside a brace; it cannot express "fits stays on one line" or blank lines between contexts, which the gate checks (§3.2).
5. **One type per file, named after it (Gate).** One top-level `struct`, `class`, `enum`, `actor` or `protocol` per file. No nested type, with two exceptions: a `CodingKeys` enum, which the compiler requires in that position, and a `@Model` class inside its `VersionedSchema` enum (§1.8), in a file named `Schema+Model.swift` (`LedgerSchemaV1+OutboxEntry.swift`) holding one extension of the schema with that one class. A file named `Type+Aspect.swift` holds only extensions of `Type`. A typealias-only file is allowed. One SwiftUI view per file. No grouped-DTO file.
6. **Layers and imports (Gate).**
   - Dependency direction as §1.3. `Models`, `Repositories`, `DTO`, `Services`, `State`, `ViewModels` and `UI/Screens` hold feature subfolders, never files; `Core/*`, `Ports`, `Routes`, `App`, `Adapters/*`, `UI/Theme` and `UI/Components` hold files directly.
   - Import allow-list: `KinetixDomain` imports `Foundation` only. `KinetixPresentation` imports `Foundation`, `Observation` and `KinetixDomain`. `KinetixData` imports `KinetixDomain` and `Foundation`, `SwiftData`, `Security`, `Network`, `OSLog`, `CryptoKit`, `Synchronization`. Test targets and `KinetixFakes` may also import `Testing` and `Synchronization`. SwiftUI and UIKit only in the app target; Firebase only under `Kinetix/Adapters/Firebase/`.
   - No UseCase or Interactor layer. No DI container. No singleton outside `AppContainer`.
7. **Failure is a value (Gate from Phase 1).** Repository methods return `Result<_, Failure>` and are not `throws`. Only the three types of §1.6 catch a transport error or read a status. Unknown is never mapped to a refusal, to empty or to zero. No `try!`, no `fatalError`, no force unwrap of a value that came from outside the process.
8. **DTOs and configuration (Gate).** Every DTO declares `CodingKeys`; no global key strategy; no default on a required field; no host or URL literal outside configuration; no fallback value for a missing setting.
9. **Concurrency (Gate).** Swift 6 mode; the constructs of §1.4 are forbidden; `Task {` appears only where §1.4 allows it; warnings are errors.
10. **SwiftUI and state (Gate from Phase 1 where a scanner can see it).** Observation only. A view owns its view model and receives it through its initialiser; the initialiser is inert. No service in the environment. Typed routes only. No user-facing string literal in a view model or a repository. No `AnyView`.
11. **Tests and previews.** Swift Testing for unit and integration tests, XCTest only for UI automation. **Hand-written fakes, no mocking or stubbing library**; fakes live in `KinetixKit/Tests/KinetixFakes/` and see only public API. No test code, fake, sample data, debug backdoor or launch-argument switch in `Sources/` or `Kinetix/`. A `#Preview` carries no domain data (§1.5). Test names carry the reasoning comments cannot. Every gate and every new test is seen red before it is trusted.
12. **Dependencies.** Apple frameworks first. Every third-party package is listed in §6.2 with its reason and pinned by a committed `Package.resolved`. None is added silently.
13. **No fake features.** Nothing ships ahead of its backend; no placeholder screen, endpoint, metric or number.
14. **Privacy and secrets.** Nothing secret in the repository or the binary. `GoogleService-Info.plist` and `Configuration/Local.xcconfig` are ignored by git. The privacy manifest and the App Store privacy answers are kept true to what the code collects.
15. **Git is the user's.** This folder is not a repository yet, and creating it is the user's. No `init`, `add`, `commit`, `push`, new branch, tag, `stash`, `reset` or `rebase`, and no switching branches; `fetch` and `pull` are allowed. When the user says something is pushed, take it and check the result (a CI run), never the push. Work lands on `development` and reaches `main` by pull request; release tags `vX.Y.Z` are cut from `main` only.
16. **Finishing a task.** Run the gate (§3.2), append to §0.2, copy `AGENTS.md` over `CLAUDE.md`, and report what was run with its test counts. A suite that printed no count is no evidence.

---

## 3. Structure and gate

### 3.1 Target layout

```text
kinetix-ios/
├── AGENTS.md, CLAUDE.md            this document, twice
├── .swift-format, .xcode-version, .gitignore
├── bin/ci                          the one gate, run locally and by CI
├── Configuration/                  App.xcconfig, Local.xcconfig.example, Info.plist, Kinetix.entitlements
├── Kinetix.xcodeproj/
├── Kinetix/                        app target (a synchronized folder)
│   ├── App/                        KinetixApp, AppContainer, AppDelegate adaptor, AppRootScreen
│   ├── Adapters/Local/             OSLog crash reporter and analytics, bundled flags, protected-data port
│   ├── Adapters/Firebase/          crash, analytics, flags, push token (the only Firebase imports)
│   ├── UI/Theme/                   palette, typography, theme
│   ├── UI/Components/              FailureMessageMapper, shared blocks
│   ├── UI/Screens/<feature>/       XScreen + XContent per screen
│   └── Resources/                  Assets.xcassets, Localizable.xcstrings, PrivacyInfo.xcprivacy
├── KinetixTests/                   hosted tests that need iOS: Keychain vault, message mapper, app wiring
├── KinetixUITests/                 XCTest UI journeys (need a reachable API; never part of bin/ci)
└── KinetixKit/                     local Swift package
    ├── Package.swift
    ├── Sources/
    │   ├── KinetixDomain/
    │   │   ├── Core/{Failure,Time,Config}/      Failure, the clock port, AppConfig and its validator
    │   │   ├── Models/{Ids,Auth,Profile,Catalog,Pricing,Search,Review,Wallet,Cart,Order,Tracking,Notary,Push}/
    │   │   ├── Repositories/<feature>/          protocols only
    │   │   └── Ports/                           CrashReporter, AnalyticsTracker, FeatureFlagProvider, PushTokenSource
    │   ├── KinetixData/
    │   │   ├── Core/Network/                    HTTPTransport, SafeApiCaller, HttpFailureMapper, ApiErrorParser, WireTimestamp
    │   │   ├── DTO/<feature>/
    │   │   ├── Services/{Remote,Session,Storage,Local,Outbox,Realtime}/
    │   │   └── Repositories/<feature>/          implementations
    │   └── KinetixPresentation/
    │       ├── Routes/                          AppRoute, AppRouter
    │       ├── State/<feature>/                 UI state enums
    │       └── ViewModels/<feature>/
    └── Tests/
        ├── KinetixFakes/                        a plain target with path "Tests/KinetixFakes", used by the test targets only
        ├── KinetixDomainTests/
        ├── KinetixDataTests/
        ├── KinetixPresentationTests/
        └── KinetixGateTests/                    the mechanical gate, scanning the whole repository
```

Typed ids (`Models/Ids/`): `AccountId`, `PrincipalId`, `ProductSku`, `CategorySlug`, `OrderId`, `OrderNumber`, `ReviewId`, `VoucherCode`, `TopUpReference`, `IdempotencyKey` are distinct types with a validating initialiser, so an `OrderNumber` passed where an `OrderId` is required does not compile.

### 3.2 The gate

This repository is the estate's exception to everything-runs-in-Docker: Xcode, the iOS SDK and the simulator run only on macOS. The pinned toolchain is the Xcode named in `.xcode-version`, and `bin/ci` refuses another. Nothing else is installed on the laptop: the formatter is the toolchain's own, and the scans run in CI. Check the laptop's memory pressure before and after `bin/ci`; the simulator step is the heavy one.

`bin/ci` is the single entry point, the same locally and in CI:

1. `cmp AGENTS.md CLAUDE.md`.
2. The formatter in lint mode, strict, with `.swift-format`, over `Kinetix`, `KinetixTests`, `KinetixUITests`, `KinetixKit/Sources`, `KinetixKit/Tests` and `KinetixKit/Package.swift`. The configuration sets 4-space indentation, one argument per line when wrapping, trailing commas in multi-line lists, existing line breaks respected, and turns on the rules against blank lines inside braces, force unwrap and force try.
3. `swift test --package-path KinetixKit`: domain, data, presentation and gate tests on the Mac, no simulator, with the explicit-target-dependency import check set to error once that flag has been seen red. Output must show a test count.
4. `xcodebuild test -project Kinetix.xcodeproj -scheme Kinetix -destination <an iOS simulator that exists> -only-testing:KinetixTests`, and the stores' and transport's suites on iOS as well *(verify that this project format accepts a local package's test target in a test plan)*. When a runtime of the minimum iOS is installed, the step runs a second time on it. `KinetixTests` is hosted, so the real app starts for every run: without a session its start-up sends nothing, and the gate relies on that. The Keychain tests use their own service name, passed through the vault's initialiser. Never write a device name into the script: pick one from `xcrun simctl list devices available`.
5. A Release build of the app **for the simulator** (a device build needs a team, IOS-D13) with warnings as errors.

UI journeys run on demand against a lab, never against production from CI.

---

## 4. Backend contracts

**Before implementing a slice, read its page and its endpoint definitions in full; they win over this digest.** The pages are prose; the fields, bounds, statuses and samples of every endpoint are in `kinetix-docs/src/site/rest/endpoints/<service>.ts` and `sockets/`. Do not invent an endpoint or a field name. What follows is what a client gets wrong most easily.

| Slice | Page under `kinetix-docs/src/content/docs/apis/rest/buyer-app/` |
| :--- | :--- |
| Accounts, sign-in, 2FA challenge, stored session | `sign-up-and-sign-in.mdx` |
| Refresh, sign-out | `stay-signed-in.mdx` |
| Managing 2FA | `two-factor.mdx` |
| Delivery profile | `profile.mdx` |
| Catalogue, flash sale, discounts, reading reviews | `browse.mdx` |
| Search | `search.mdx` |
| Wallet and top-up | `wallet-top-up.mdx` |
| Cart and vouchers | `cart.mdx` |
| Checkout | `checkout.mdx` |
| Orders and live tracking | `orders.mdx` |
| Writing reviews and ratings | `reviews.mdx` |
| Notary proofs | `proofs.mdx` |
| Push | `push-notifications.mdx` |
| Hosts, tokens, request ids | `../index.mdx` (its "Limits" and gateway answers describe the previous engine: use §1.6) |

### 4.1 Identity, session, sign-in delay and 2FA

- **Where tokens are checked.** On `/api/v1/auth` (except `login`, `register`, `refresh` and `2fa/verify`, which are public at the gateway), `/api/v1/users`, `/api/v1/payment`, `/api/v1/proofs` and `/api/v1/notifications/devices` the gateway checks issuer, signature and expiry first (its own `401`). Catalog, search, pricing, order and review check the token themselves.
- **Register (`POST /api/v1/auth/register`)**, body `{ email, password }`: email at most 254 characters; password at least 12 characters and at most 72 bytes in UTF-8. `201` is a session: `accessToken`, `refreshToken`, `expiresIn`, and `user` with `id`, `email`, `role`, `principalId`. **Keep both ids**: `user.id` (`AccountId`, an integer) is what identity's own paths take; `user.principalId` (`PrincipalId`, a UUID) is the `sub` every other service knows the buyer by. `409`: the email has an account.
- **Sign in (`POST /api/v1/auth/login`)** accepts a password of 6 to 1,024 characters: **never apply the registration minimum to the sign-in form.** A `200` is one of three shapes: a session; a challenge (`mfaRequired: true`, `challengeToken`, `expiresIn`, `passkeys`); or `mfaEnrolmentRequired` with an `enrolmentToken`, which only an `admin` account receives and which the app refuses, discarding the token without calling logout.
- **Role.** Register always creates a `customer`, but sign-in, the challenge and refresh answer a session for any role. After every session answer read `role`: for anything but `customer` the wallet routes answer `403`; say that this app is for buyer accounts and never retry it. A role can change at a refresh.
- **Three waits, all `429`.** The gateway's shared budget (§1.6). identity's per-address throttle. And `error: "SIGN_IN_DELAYED"`, which counts every check of this account's password or code from any device: after five in a row the wait grows from 1 s to at most 60 s and the account is never locked. Read `retryAfterSeconds` from the body, falling back to `Retry-After`; tick a countdown; keep the screen and any challenge intact.
- **Answer the challenge (`POST /api/v1/auth/2fa/verify`)**, body `{ challengeToken, code }`. `200` is a session. `401 WRONG_CODE` leaves the challenge open. `401 CHALLENGE_EXHAUSTED`, `CHALLENGE_SPENT` or `CHALLENGE_INVALID` can never succeed: return to the password step.
- **Refresh (`POST /api/v1/auth/refresh`)**, body `{ refreshToken }`. Refresh tokens rotate on every use. The outcomes are §1.7's table. Lifetimes today are 900 s and 30 days *(read: production configuration)*; the app reads `expiresIn`.
- **Stored session (`GET /api/v1/auth/me`)**: `200` repeats `principalId`, `userId`, `role`, `expiresAt`.
- **Sign out.** Forget the handset first, while the access token is valid (§4.11). Then `POST /api/v1/auth/logout` with the Bearer token and body `{ refreshToken }`, which ends this session alone; leaving the field out ends every session of the account; `null` is refused. The gateway checks the token on this route, so renew first if it has expired. `204`, then discard both tokens; discard them also if the call has not answered within 5 seconds (a named constant).
- **Managing 2FA (`POST /api/v1/auth/2fa/{setup,enable,disable}/{id}`)**, `{id}` = `AccountId`. Setup takes `{ password }` and returns `qrCodeUrl` (an `otpauth://` URI, rendered as a QR code on the device), `twoFactorSecret` and `enabled: false`; `409` means it is already on. **Enable and disable both take `{ code, password }`**, `code` being the six digits shown now. Without `password`, setup and enable answer `400 PASSWORD_REQUIRED`; disable answers a validation `400` (a `message` array). `422` is a wrong or reused code; `409` on disable means it is not on. A `401` here is a wrong password, **not** an expired session: keep the tokens and ask again. Enabling or disabling ends every other session of the account. These calls count towards `SIGN_IN_DELAYED`.

### 4.2 Delivery profile (`identity`)

- `GET /api/v1/users/{id}/profile`: `404` on an account that never saved one, which is a state to render, not an error.
- `PUT /api/v1/users/{id}/profile` creates it, then changes only the fields sent. Send only what changed and never `null`, except `avatarUrl: null`, which removes the avatar; `null` anywhere else is a `400` and nothing is saved. `409` means another request created the profile at the same moment: read it and send the change again. A changed address is placed on the map before the answer, which can take several seconds and can outlast the gateway's 15 s (§1.6): a `504` there is outcome unknown, settled by reading the profile. The `200` carries the whole profile.
- Checkout does not read the profile: the app pre-fills `recipientName`, `recipientPhone` and `shippingAddress` from it.

### 4.3 Catalogue, search, promotions and reading reviews (no token needed)

- `GET /api/v1/categories`: `id`, `name`, `slug`. Keep `slug` for filtering and for search facets.
- `GET /api/v1/products` with `category` (slug), `q`, `page` (up to 10,000), `page_size` (1 to 100, default 10) answers `{ count, page, page_size, results }`. In each result `weight_grams`, `available_stock` and `is_in_stock` are **nullable** (the last two are `null` when `stock_status` is `unknown`) and `image_url` may be an empty string. `stock_status` is `in_stock`, `out_of_stock` or `unknown` (warehouse could not be asked). **Never show `unknown` as out of stock.**
- `GET /api/v1/products/{sku}` (percent-encode the SKU) is keyed by `sku`, never by the numeric `id`. It answers the product with `description` and **without** the three list stock fields: stock is `warehouse_stock { sku, bin_location, available_quantity, reserved_quantity, stock_status }`, whose middle three are null when `stock_status` is `unknown`.
- `GET /api/v1/pricing/flash-sales/{product_id}` where the id is the `sku`. A `null` body means no sale. Checkout uses the flash price only when it is below the catalogue price, and then gives that unit no discount.
- `GET /api/v1/pricing/discounts`: one unpaged list the app matches itself. A discount concerns a product when its `target_product_id` is the product's `sku`, **or** its `target_category_id` is the product's `category_slug`, **or** it names neither; **and** its `merchant_principal_id` is `null` or the product's merchant. Of those, pricing applies only the one that saves most on a unit (`PERCENTAGE`: price × `value` ÷ 100; `FIXED`: `value` rupiah; never more than the price). The indication shows that one and never adds discounts together. Those three target and merchant fields are nullable.
- Every price here is an indication; checkout prices the cart again.
- `GET /api/v1/products/suggest?q=&limit=` returns `{ suggestions }`; a blank `q` is an empty list. `GET /api/v1/products/search?q=&category=&sort=&limit=&offset=` returns `{ total, hits, facets, index }`: `facets` may be absent, a hit's `description` and `categories` may be absent, `index.indexed_through_ms` and `index.age_seconds` may be null. A hit's `id` is the `sku`; open it through `GET /api/v1/products/{sku}`. When `index.stale` is `true`, show the hits with a non-blocking note.
- `GET /api/v1/reviews/products/{productId}?page=` (`productId` is the `sku`; `page` at least 1, up to `last_page`; an unknown key is an empty list) and `GET /api/v1/reviews/merchants/{merchantPrincipalId}?page=`.

### 4.4 Wallet and top-up (`payment`, role `customer`)

- Checkout pays only from the buyer's Kinetix wallet. `GET /api/v1/payment/wallet/customer/balance` returns `availableBalance`; a wallet never funded answers `exists: false` at zero.
- **Start a top-up:** `POST /api/v1/payment/wallet/customer/topup` with `Idempotency-Key` (1 to 128 characters from `A-Z a-z 0-9 . _ : -`; a UUID fits) and body `{ amount, paymentMethod, bank? }`: `amount` a JSON number of whole rupiah, at least 1,000 and at most payment's limit (IDR 2,000,000 today, a configured value); `paymentMethod` `MIDTRANS_VA` or `MIDTRANS_QRIS`; `bank` one of `BCA`, `BNI`, `BRI`, `CIMB`, `PERMATA`, required with VA and refused with QRIS. **Create the key, store key and body in the ledger, then send.**

| Answer | Meaning | Then |
| :--- | :--- | :--- |
| `202` | `referenceNumber` and `instructions` (nullable: `bank`, `virtualAccountNumber` or `qrCodeUrl`, and `expiresAt` as Midtrans' own text) | keep the reference; a replayed `202` may already be past `PENDING` |
| `502` with `referenceNumber` | Midtrans refused; the top-up is `FAILED`, nothing was charged | final for that key; a new attempt needs a new key |
| `503` with `referenceNumber` | still `PENDING` and may still be paid | follow it; do not start another |
| `409` | the key was used with another body | repeat the original body or use a new key |
| `422` with `code` `TOP_UP_AMOUNT_ABOVE_LIMIT` or `WALLET_BALANCE_LIMIT_EXCEEDED` (`limit` is a string) | refused | while one is `PENDING`, take the buyer back to that top-up's instructions |
| any other `503`, a `500`, an answer without payment's JSON, no answer | outcome unknown | send the same key and body again |

- A top-up may not take the wallet above the limit, every `PENDING` top-up counts against it until it leaves `PENDING`, and a top-up cannot be cancelled.
- **Read it:** `GET /api/v1/payment/wallet/customer/topup/{referenceNumber}`. Statuses are `PENDING`, `SUCCESS`, `FAILED`, `EXPIRED`, `NEEDS_ATTENTION` (set aside for a person; nothing credited). Stop polling on anything but `PENDING`; on `SUCCESS` read the balance again; `404` is no such top-up for this buyer. A `PENDING` top-up that never reached Midtrans is concluded `FAILED` by payment only after an hour. No endpoint lists a buyer's top-ups (§7 Q7).

### 4.5 Cart and vouchers (`order`: a session is required; `pricing`: none)

- One cart per buyer, kept by order under the token's `sub`; there is no guest cart. It expires 14 days after its last change, and reading does not extend it: an empty cart is a state, not an error. `GET /api/v1/cart` returns `{ items, appliedVoucherCode, subtotal }`.
- `POST /api/v1/cart/items` `{ productId: <sku>, quantity }` **adds** to the line. `PUT /api/v1/cart/items/{productId}` sets the quantity (`0` removes the line). `DELETE /api/v1/cart/items/{productId}` removes it. Each answers the whole cart. A line holds 1 to 999. `409 CART_BUSY`: nothing changed, repeat the edit. `503 CART_UNAVAILABLE` or `CATALOG_UNAVAILABLE`: nothing changed, try later. Read the endpoint for the refusals an add can get.
- `DELETE /api/v1/cart` is for an explicit "empty the cart" action only, and **never** after a checkout.
- **The two voucher endpoints take different field names.** pricing's preview, `POST /api/v1/pricing/vouchers/apply`, takes `{ code, cart_subtotal, merchant_principal_id }` and answers `200` with a `null` body when the code does not apply. order's `POST /api/v1/cart/voucher` takes **`{ voucherCode }`** (not blank, at most 50 characters; `400 VOUCHER_CODE_REQUIRED` otherwise); `DELETE /api/v1/cart/voucher` removes it; both answer the whole cart. `GET /api/v1/pricing/vouchers/{code}` reads the terms (`value`, `min_spend`, `max_discount` nullable, `expires_at`).
- The cart's `subtotal` is at catalogue prices while checkout compares `min_spend` with the subtotal after flash sales and discounts, so a preview can accept a code checkout will not grant: say so, and trust the order's `appliedVoucher`.

### 4.6 Checkout (`order`)

- Every line must share one `merchantPrincipalId`; warn in the cart.
- `POST /api/v1/orders/checkout` with `Authorization` and `Idempotency-Key` (at most 100 characters; a fresh UUID), body `{ shippingAddress, recipientName, recipientPhone, shippingServiceTier?, voucherCode? }` (at most 500, 128, 32 and 50 characters). **Order does not refuse a missing key: it runs an unprotected checkout.** The checkout client must be unable to build a request without one. `voucherCode` replaces the cart's code, an empty string checks out with none, and leaving it out uses the cart's. Without a tier, order takes the cheapest that can carry the parcel; a refused tier comes back with `availableTiers`.
- A `201` is an order, normally **`PAID`**: stock reserved, pricing computed, the wallet debited into escrow. Read `status` from it: a replayed `201` is the order as it stands now and can be further on, or `CANCELLED`. Keep `id` (`OrderId`, to read, review and track) and `orderNumber` (`OrderNumber`, for the notary).
- **One new key per checkout, kept in the ledger with the body until a final answer.** Classify by order's `error` code whenever the body is order's JSON, and by status alone only when it is not:

| Group | Answers | What the app does |
| :--- | :--- | :--- |
| Key spent | `201`; `409 CHECKOUT_ROLLED_BACK` and `409 CHECKOUT_ROLLBACK_PENDING` (also with `replayed: true`; `reason` starts `voucher:`, `flash sale`, `stock for`, `escrow:` or `fulfilment:`; `escrow:` covers a wallet short of the total among other refusals of the hold); `503 CHECKOUT_DEPENDENCY_UNAVAILABLE` | Final for that key. Another attempt needs a new key |
| Outcome unknown | `409 CHECKOUT_IN_PROGRESS`; `500 INTERNAL_ERROR`; `503 DATABASE_UNAVAILABLE`; any `502`, `503` or `504` that is not order's JSON; no answer | Repeat the same request with the same key and body. Order finishes or unwinds a stopped checkout after about 5 minutes and cancels one that never started after about 15: the repeat schedule reaches that far |
| Key reused | `422 IDEMPOTENCY_KEY_REUSED` (carries the earlier `orderNumber`) | Repeat the original body exactly, or use a new key for a new intention |
| Key unused, refused | every other `400`; `404 PRODUCT_NOT_IN_CATALOG`; `409 MERCHANT_NOT_TRADING`; every other `422` (`CART_EMPTY`, `CART_SPANS_TWO_MERCHANTS`, `SHIPPING_ADDRESS_NOT_PLACED` with a `reason`, which means the address must change, and the rest on the endpoint); order's own `502 SHIPPING_QUOTE_MALFORMED`, `SHIPPING_FEE_CONTRADICTED`, `ORDER_AMOUNTS_UNCHARGEABLE` | Nothing was written or charged. Fix what the code names and send again; the three `502` codes are a server fault and are never repeated automatically |
| Key unused, could not ask | order's `503` with `CART_UNAVAILABLE`, `CATALOG_UNAVAILABLE`, `IDENTITY_UNAVAILABLE`, `ADDRESS_LOOKUP_UNAVAILABLE`, `SHIPPING_UNAVAILABLE` or `PRICING_UNAVAILABLE` | Repeat unchanged after a wait |

- The Phase 3 state machine is keyed on (status, error code, whether the body is order's JSON), never on status alone.
- After a `201`, order removes from the cart only what that checkout bought. **Read the cart again; never clear it.**

### 4.7 Orders (`order`)

- `GET /api/v1/orders/my-orders?page=&pageSize=&status=` answers `{ items, page, pageSize, totalCount }` (`pageSize` 1 to 100, default 10; pages up to 10,000), newest first, ties by `id`. Pages are cut by position, so an order placed meanwhile repeats rows: **deduplicate by `id`**, and read page 1 again to see new orders.
- `status` is `PENDING_PAYMENT`, `PAID`, `PROCESSING_FULFILLMENT`, `DELIVERED`, `COMPLETED` or `CANCELLED` (`SHIPPED` and `REFUNDED` exist and are never set); any other value maps to the unknown case. Order has no assigned or picked-up status.
- `GET /api/v1/orders/{orderId}` takes the UUID `id`, never the `orderNumber`. It shows `status`, lines, amounts, and `driverPrincipalId`, which stays `null` until a courier has delivered.

### 4.8 Live courier tracking (`edge`)

- `wss://<ws host>/ws/v1/events`; when it opens and closes is §1.9. A buyer connects to the edge alone.
- Subscribe: `{ "event": "subscription.subscribe", "requestId": "<uuid>", "schemaVersion": 1, "data": { "orderId": "<order UUID>" } }`. Heartbeat: the same envelope with `"event": "system.ping"` and `"data": {}`. Leaving the screen: `subscription.unsubscribe` with the subscribe's `data`.
- **Two frame families share the socket.**
  - The edge's own (`command.ack`, `command.error`, `system.pong`): `eventId`, `requestId` (absent when the frame we sent could not be parsed), `schemaVersion`, `occurredAt` and `sentAt` in whole seconds, and `data` or `error`. An ack's `data` carries `subscribed`, `orderId`, `orderNumber`; an error's `error` carries `code`, `reason`, `message`, `retryable`.
  - matching's (`courier.location.updated`), coalesced to at most one frame every 250 ms per order: `event`, `eventId` (an opaque string), `schemaVersion`, `orderId` (here the **order number**), `sequence` (`null` on this event), `occurredAt`, and `data` with `driverId` (an integer: matching's driver row, never a principal id), `latitude` and `longitude` (numbers, always present), `bearingDeg` and `speedKmh` (**number or `null`**: `null` whenever the fix carried no heading or speed, as a phone standing still), `recordedAt` (always present, microseconds). The published sample shows numbers only; decode both as optional and keep the last known heading.
- `command.error` codes: `INVALID_ORDER_ID`, `FORBIDDEN`, `ORDER_NOT_FOUND`, `INVALID_JSON`, `INVALID_PAYLOAD`, `UNKNOWN_EVENT`, `UNSUPPORTED_SCHEMA_VERSION`, and `UPSTREAM_UNAVAILABLE`, the only `retryable: true` code, which also covers order refusing the handshake token as expired (§1.9).
- Handshake refusals a buyer can get, each `{ error, message, requestId }`: `401 SESSION_REQUIRED` or `SESSION_ENDED`, `426 WEBSOCKET_REQUIRED`, `429 TOO_MANY_REQUESTS`, `502 IDENTITY_FAILED`, `503 IDENTITY_UNAVAILABLE`; the gateway can add its own `429` and `503`.

### 4.9 Writing reviews and courier ratings (`review`)

- Offered only when the order's `status` is `DELIVERED` or `COMPLETED`.
- `POST /api/v1/reviews/products` `{ order_id, product_id, rating, comment }`, one per order line: `order_id` is the order's UUID (`orderNumber` is refused with `422`), `product_id` the line's `productId`. `POST /api/v1/reviews/drivers` `{ order_id, rating, comment }`, one per order, only when the order has a `driverPrincipalId`.
- `rating` is a JSON integer from 1 to 5; `comment` is optional and at most 1,000 characters (the form enforces it, counting Unicode scalars), with NUL (U+0000) stripped before sending. Breaking either is `422 VALIDATION_FAILED`, a definite refusal the outbox never retries.
- Keep the id for the notary: `id` from a `201`, or `review_id` from a `409`, which means it is already done and is shown as done. A write whose outcome is unknown is sent again unchanged and ends in one of those two answers.

### 4.10 Notary proofs (`notary`)

- `GET /api/v1/proofs/liabilities/{epoch}`, `{epoch}` being `latest` or decimal digits without a leading zero: `{ proofs }`, each document kept whole. Empty means nothing was owed at that epoch.
- `GET /api/v1/proofs/evidence/orders/{order}` takes the **`orderNumber`**, not the UUID; while `pending` is above 0, ask again later. `GET /api/v1/proofs/evidence/reviews/{review}` takes the review id from §4.9.
- **Registering a wallet address.** `GET /api/v1/proofs/registrations` returns the EIP-712 typed data whole: `types`, `primaryType`, `domain` (its `chainId` a JSON number) and `message.principal`. It is passed to the wallet as received, with two fields added to `message`, never rebuilt from parts: `holder` (the wallet's own address) and `issuedAt`, **the current Unix time in whole seconds written as a decimal string** (`"1792638900"`). The wallet signs with `eth_signTypedData_v4`. `POST /api/v1/proofs/registrations` sends exactly `{ holder, issuedAt, signature }`: the same decimal string that was signed, and the signature as 65 bytes of hex. Any other field, or `issuedAt` as a JSON number or an ISO string, is `400 invalid_request`. A request older than 5 minutes, more than a minute ahead of the notary's clock, or signed by another address is `403 registration_refused`: sign again with the current time. The `200` is kept whole (`court`, `epoch`, each registration's `digest` and `signature`, which the wallet presents on chain).
- **How the wallet is reached (IOS-D14).** The app puts the template in the fragment of a URL to a signing page owned by `kinetix-docs` and shows that URL as a QR code and as a link to share. The buyer opens it where the wallet lives: a desktop browser with a wallet extension, or a wallet app's own browser. The page adds the two fields, asks the wallet for the signature, and shows `{ holder, issuedAt, signature }` as a QR code and as text. The app takes that back by scanning or by paste, checks its shape (`holder` an address, `issuedAt` decimal digits, `signature` 65 bytes of hex), and posts it at once. The app never holds a key and adds no wallet SDK and no relay. The page does not exist yet (§7 Q9): until it does, the app offers the proofs and the evidence only.

### 4.11 Push and the device-ownership challenge (`notification`)

- `POST /api/v1/notifications/devices` `{ device_token: <FCM token>, platform: "IOS" }`, when §1.10 says. `200`: done. `202`: another principal holds the token; wait for the proof message.
- The proof is an FCM data message `{ kind: "DEVICE_VERIFICATION", nonce, expires_at }`. Answer before `expires_at` with `POST /api/v1/notifications/devices/verify` `{ device_token, nonce }` and the same buyer's access token.
- `429 VERIFICATION_ALREADY_PENDING`: a proof is on its way; verify with the nonce already sent, and register again after `Retry-After` only if it never came. `429 VERIFICATION_LIMIT_REACHED`: register again after `Retry-After`. `422 VERIFICATION_FAILED`: the nonce is not the pending one (five tries in all); never resend the same nonce. `422 VERIFICATION_NOT_PENDING`: register again. `422 ADDRESS_GONE`: ask the Firebase SDK for a new token and register that. `503 SENDER_UNAVAILABLE`: later (this is also what a missing APNs key in the Firebase project looks like, §7 Q2). `502 SENDER_REJECTED`: do not repeat unchanged.
- **Forget:** `DELETE /api/v1/notifications/devices` with the **JSON body `{ device_token }`** and the buyer's access token. `204` whether or not this buyer held the token, so it is safe to repeat. Without the body it is `400 MALFORMED_BODY` and nothing is forgotten, and the handset would keep receiving the pushes of a buyer who signed out. Called before sign-out and for the old token whenever the SDK replaces it.

### 4.12 Deferred until the backend ships (do not fake)

- **Chat.** Designed as MQTT 5 to EMQX with HTTP for queries, but communication and EMQX are not deployed.
- **Seal verified anonymous reports.** Production already serves the reporter and report routes (seal v1.12.0); what the buyer app waits for is a published buyer contract (§7 Q14). Nothing is built from the seal source.
- **App integrity, associated domains, passkey sign-in, push routing, order notifications.** Each waits on an owner (§7).
- **Anything the researched proposal assumed and no service provides**: a wishlist, a marketing home feed, price-drop alerts, a guest cart.

---

## 5. Phased implementation plan

Vertical slices in order. A slice is done when §8 holds and §0.2 says so. Infrastructure arrives with its first real consumer, never as an empty shell.

### Phase 0 — Boilerplate cleanup, package skeleton, gate

- [x] Project settings, verified via `xcrun xcprojformatter` and `xcodebuild`: bundle identifier `com.kinetix.shop`; Swift 6 language mode with the settings of §1.4; warnings as errors; deployment target iOS 18.0 in the project, with the `KinetixTests` override removed (IOS-D1); iPhone only (IOS-D7): `TARGETED_DEVICE_FAMILY = 1`, portrait as the only iPhone orientation, the iPad orientation key removed, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` and `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO`; `Configuration/Info.plist` and `App.xcconfig` as §1.12.
- [x] Remove the template: `Item.swift`, the sample `ContentView`, the SwiftData container with `fatalError`, every header comment, the placeholder unit test, the UI test template's comments and launch-performance test.
- [x] `.gitignore` (user data in the project bundle, build output, `Configuration/Local.xcconfig`, `GoogleService-Info.plist`), `.xcode-version`, `.swift-format`, `Configuration/Local.xcconfig.example`.
- [x] Create `KinetixKit` with `swift package init` run inside an empty `KinetixKit/` directory (so the tools-version line is the toolchain's own), delete what it generated except that first line, and write the manifest to §1.3 and §1.4: three library targets, the fakes target with its explicit path, four test targets. Add the package to the project and record the resulting `project.xcproj` shape in §0.2.
- [x] `AppConfig`, `AppConfigValidator`, `ConfigErrorScreen`, `AppContainer`, `AppRootScreen`, the theme tokens, the String Catalog in English and Indonesian: the first screen is the configuration check.
- [x] `KinetixGateTests` for rules 3, 5, 6, 8 and 9 and for the layout checks of rule 4 the formatter cannot express, each seen red; `bin/ci`.
- [x] CI on GitHub Actions (IOS-D12): `verify` aggregating `package-and-lint`, `simulator-and-release-build`, and `security` (Trivy critical scan + SPDX SBOM); `.github/workflows/release.yml`, `.github/dependabot.yml`, `.coderabbit.yaml`, and `.github/PULL_REQUEST_TEMPLATE.md`.

### Phase 1 — Identity, session, 2FA and delivery profile

- [x] The transport arrives with its first caller: `HTTPTransport`, `SafeApiCaller`, `HttpFailureMapper`, `ApiErrorParser`, `WireTimestamp`, request ids; `Failure`, the typed ids, the clock port.
- [x] Session: the Keychain vault, the could-not-read state, the first-launch decision, `SessionRenewer` with the three outcomes of §1.7 and the transaction-metrics rule.
- [x] Identity client and DTOs; `SessionRepository`, `AuthRepository`, `TwoFactorRepository`: the three sign-in shapes, the role check, the three `429` waits with the countdown, `WRONG_CODE` against a spent challenge, the wrong-password `401` that keeps the session. Sign-out is logout at identity within its budget; the forget-the-handset step that precedes it is added in Phase 4.
- [x] `ProfileRepository`: the `404` state, field diffing, never `null` except `avatarUrl`, the `409` retry, the `504` settled by a read.
- [x] The stores arrive with their first consumers: the cache (profile) and the ledger with the outbox (profile update), with owners. **The IOS-D5 tripwire is part of this phase**, on the Mac and on an iOS simulator (iOS 18.0 runtime run still owed once installed).
- [x] `AppRoute`, `AppRouter`; screens: sign-in, register, 2FA verification, 2FA settings, profile. The local crash and analytics adapters arrive with their first callers.
- [x] Extend the gate to rules 7 and 10.
- [x] Tests, each seen red: every branch above; the single-flight renewer under concurrent callers; a could-not-read Keychain status is never treated as no session, and the first-launch decision is not taken while protected data is unavailable; a phone change then an address change queue one `PUT` carrying both; a ledger entry and an outbox entry of principal A are neither repeated nor drained while principal B is signed in, and are still there when A signs in again; the outbox backoff with a fake clock.

### Phase 2 — Catalogue, search, promotions, reading reviews

- [ ] Catalog, search, pricing and review clients; the discount-matching rule, the best-discount rule and flash-sale priority in `KinetixDomain`, tested as tables; the money and timestamp table tests of §1.6.
- [ ] The catalogue cache and the image pipeline (IOS-D11).
- [ ] Screens: home (categories, paged products, the three stock states), search (debounced suggestions with cancellation, facets, the stale-index note), product detail (warehouse stock, flash sale and discount indication, product and merchant reviews).

### Phase 3 — Wallet top-up, cart, vouchers, checkout

- [ ] Wallet: balance, top-up with a ledger-backed key and body, every row of §4.4's table, the five statuses, polling that stops in the background.
- [ ] Cart and vouchers: the two field names, the single-merchant warning, the preview caveat, `CART_BUSY`.
- [ ] Checkout: the classification of §4.6 as a pure function in `KinetixDomain` keyed on (status, code, body origin), tested as a table; the unfinished-checkout prompt after a kill (IOS-D17); the cart read again after a `201`.
- [ ] Screens: wallet (VA and QRIS instructions), cart, checkout. The bundled flag provider arrives with `checkout_enabled` and `wallet_topup_enabled`.

### Phase 4 — Orders, live tracking, writing reviews, proofs, push, telemetry

- [ ] Orders list with cross-page deduplication, order detail.
- [ ] `EdgeEventSocket` and the tracking repository; the tracking screen on MapKit; everything in §1.9, starting with the proof of what a refused upgrade exposes.
- [ ] Review and rating writes through the outbox.
- [ ] Notary proofs and evidence with byte-exact export. Wallet registration follows IOS-D14 and waits for the signing page (§7 Q9).
- [ ] Firebase adapters beside the local ones: crash reporting, analytics, flags, and messaging with the device challenge (IOS-D6). Sign-out forgets the handset first. While IOS-D13 is deferred the challenge handler is proven with simulated pushes (`xcrun simctl push`) and delivery end to end stays open.
- [ ] MetricKit and signposts.

### Phase 5 — Deferred features

- [ ] Chat, seal reports, App Check, associated domains and passkeys, push routing: each when §7 closes its question.

### Phase 6 — Release engineering

- [ ] Signing, the privacy manifest and App Store privacy answers, `release-preflight` (refuse to archive without the plist for `com.kinetix.shop`), TestFlight from a tag on `main`, phased release, release-health watch. Blocked on IOS-D13.

---

## 6. Decisions

### 6.1 Register

"Ruled" is the user's decision. "Decided" is an engineering choice made on a clear recommendation and open to overrule. "Deferred" is the user's to take up later.

| Id | Decision | Status |
| :--- | :--- | :--- |
| IOS-D1 | Minimum iOS **18.0**; the package declares iOS 18 and macOS 15. It runs on the same iPhones as iOS 17 (iPhone XS and XR onward, *verified from the device profiles*). SwiftData's `#Unique` and `#Index` and the standard library's `Mutex` start there. Cost not yet paid: no iOS 18 runtime is installed, so the minimum is untested; installing one is the user's to start | Ruled 2026-11-19 |
| IOS-D2 | One local package `KinetixKit` with three layer targets; presentation and view models outside the app target | Decided 2026-11-19 |
| IOS-D3 | No UseCase layer; repositories return `Result<_, Failure>`; hand-wired composition root | Decided 2026-11-19 (estate parity) |
| IOS-D4 | Swift 6 language mode everywhere; main-actor default in the app and presentation, nonisolated in domain and data; approachable concurrency in every target, `@concurrent` for work that leaves the caller's actor | Decided 2026-11-19 |
| IOS-D5 | SwiftData for both stores, with the Phase 1 tripwire; SQLite for the ledger if the tripwire fails | Decided 2026-11-19 |
| IOS-D6 | Firebase Messaging (fixed by the backend), Crashlytics, Analytics and Remote Config, behind ports, for parity with `kinetix-android`. All four are on Firebase's no-cost plan | Ruled 2026-11-19 |
| IOS-D7 | iPhone only, portrait only, for the first release | Ruled 2026-11-19 |
| IOS-D8 | The palette and brand mark follow `kinetix-docs` (`kx-tokens.css` dark tokens and `kinetix-mark-dark.svg`); dark only; platform typefaces. Supersedes the earlier 2026-11-19 ruling that copied `kinetix-android`'s Obsidian/Electric Volt palette | Ruled 2026-11-19; amended 2026-11-20 |
| IOS-D9 | Multilingual buyer copy on both buyer apps: English as the development language, Indonesian added in the resource files (the String Catalog here, `values-in/` on Android). Code and documents stay English | Ruled 2026-11-19 |
| IOS-D10 | MapKit for the tracking map | Decided 2026-11-19 |
| IOS-D11 | Nuke as the image pipeline, if it compiles clean in Swift 6 mode without concurrency escapes; otherwise a small pipeline of our own on ImageIO | Decided 2026-11-19 |
| IOS-D12 | CI is GitHub Actions on its `xcode-27` Apple Silicon macOS runners (confirmed 2026-11-20 from `actions/runner-images` to include `/Applications/Xcode_27.2.app`); `bin/ci` on the developer's Mac stays the first gate. `xtool` on Linux runners was considered and not adopted: there it has no asset catalogs and no simulator, its handling of this project format and of SwiftData's macros is unproven, it cannot upload a release, and Apple's licence for the SDK it unpacks is in question. The GitLab mirror runs no iOS job unless one is asked for | Ruled 2026-11-19 |
| IOS-D13 | Apple Developer Program membership, the App Store Connect record, the APNs key in the Firebase project and the iOS app `com.kinetix.shop` registered there. Development continues on the Simulator and a free Personal Team. Without the membership there is no push entitlement, no TestFlight or App Store build and no associated domains | Deferred 2026-11-19 |
| IOS-D14 | The wallet signs the notary registration on a page owned by `kinetix-docs`: QR out, QR or paste back (§4.10). No wallet SDK, no relay; the same page serves `kinetix-android` | Ruled 2026-11-19 |
| IOS-D15 | Releases are plain `xcodebuild` with an App Store Connect API key. No Fastlane: it would add a second language for no capability | Decided 2026-11-19 |
| IOS-D16 | What goes through the outbox: profile updates, reviews and ratings. No cart write does, including the ones that are safe to repeat; checkout and top-up are online only. Stricter than `kinetix-android`, which names cart writes among its outbox operations | Decided 2026-11-19 |
| IOS-D17 | An unfinished checkout or top-up found at start is never sent without the buyer: the app asks. Silent replay is the alternative; it can debit the wallet for a cart that changed since, so choosing it is the user's (money) | Decided 2026-11-19, the conservative choice |
| IOS-D18 | A `#Preview` renders only states that carry no domain data. Stricter (no previews, as Android) or looser (sample data in previews, which the estate's rule against demo data in sources forbids) is the user's to grant | Decided 2026-11-19 |

### 6.2 Third-party packages

None is installed yet. Planned, each added in the phase that first needs it:

| Package | Why | Phase |
| :--- | :--- | :--- |
| Firebase Apple SDK (Messaging, Crashlytics, Analytics, Remote Config) | The backend sends push through FCM only; the rest by IOS-D6 | 4 |
| Nuke | Image decoding, downsampling, caching and cancellation for product grids (IOS-D11) | 2 |

### 6.3 Where this app differs from `kinetix-android`, and why

The two apps keep the same contracts, failure classification, typed ids, flag keys and analytics names. They differ here:

| Concern | `kinetix-android` | `kinetix-ios` | Why |
| :--- | :--- | :--- | :--- |
| Dependency injection | Hilt | hand-wired `AppContainer` | the estate's no-container rule; Android is the outlier |
| Modules | one `:app` module, gated | one package with three targets, gated | IOS-D2 |
| Local store | one Room database | two SwiftData stores | different promises (§1.8) |
| Background sync | WorkManager with constraints | drains on enqueue, activation and network return, plus an opportunistic refresh task | iOS gives no guarantee |
| Session at rest | an AES-GCM file under the Keystore | one Keychain item | platform |
| Device challenge | high-priority FCM data message | background push, dropped when it cannot be handled | platform (§1.10) |
| Trace header | `traceparent` and a request id | a request id only | nothing reads `traceparent` |
| Unfinished checkout after a kill | not specified | the buyer is asked | IOS-D17 |
| Cart writes offline | named among outbox operations | never queued | IOS-D16 |
| Previews | none | domain-free states only | IOS-D18 |
| Brand palette | earlier Obsidian / Electric Volt tokens | `kinetix-docs` (`kx-tokens.css`) warm dark & terracotta tokens | IOS-D8 amended 2026-11-20 by user |

Three things in `kinetix-android` must not be copied; they are raised with it in §7 Q8.

### 6.4 Triage of the researched proposal

| Proposal | Verdict | Why |
| :--- | :--- | :--- |
| SwiftUI, Swift 6 concurrency, Observation, `NavigationStack`, constructor injection with a composition root, `URLSession`, Keychain, Swift Testing with XCTest UI, MetricKit, OSLog, remote flags, a definition of done | Adopted | Fits the platform and the estate's rules |
| One realtime connection manager, backoff, snapshot over REST after a reconnect, foreground-only sockets, background-execution realism | Adopted | Matches the edge socket's contract |
| Offline-first with an outbox | Adapted | Only for writes the contract makes safe and that no screen waits on (IOS-D16) |
| Clean Architecture with use cases | Adapted | The estate has no UseCase layer; the hexagon stays |
| 11 core and 15 feature packages | Adapted | One package, three layer targets |
| SwiftData everywhere | Adapted | Two stores with different promises, and a tripwire |
| Development, staging and production with mock services | Adapted | No staging exists; mocks are forbidden; two fail-fast values |
| Sequence numbers for missed events | Adapted | The envelope carries `sequence`, but it is `null` on the only event a buyer receives |
| GitHub Actions, TestFlight, an ADR folder | Adapted | CI by IOS-D12; release by IOS-D15; reasoning lives in this file |
| NATS JetStream; Kong as the engine | Rejected | The estate uses gRPC and RabbitMQ; the gateway is Envoy; neither concerns a client |
| OAuth 2.0 / OIDC with PKCE in a browser session | Rejected | Identity's contract is a JSON sign-in with a TOTP challenge |
| APNs as the provider | Rejected | The notification service sends through FCM only |
| Sentry and PostHog | Rejected | A second vendor beside the one `kinetix-android` already uses |
| Fastlane, Renovate | Rejected | A second language; the estate uses Dependabot |
| Wishlist, marketing home feed, price-drop alerts, guest cart, chat, push deep links | Rejected for now | No service provides them, or it is not deployed |
| Universal Links on `kinetix.com`, App Attest, certificate pinning, biometric gate | Deferred | No such host; not enforced by the backend; no threat model yet |

---

## 7. Questions for the owning services

Never worked around in the app. Each is raised with its owner and closed here.

| Id | Owner | Question |
| :--- | :--- | :--- |
| Q1 | edge | Answered from source (§1.9): the token is checked once at the handshake and reused for every subscribe; an expired one surfaces as `UPSTREAM_UNAVAILABLE`, retryable, though no retry on that socket can succeed. Request: answer an expired token as such, or close the socket at `exp`, and say so on the published page |
| Q2 | the user (IOS-D13) | The APNs key in the Firebase project that sends notification's pushes, and the iOS app `com.kinetix.shop` registered in it. Nothing in the repositories shows either. A `200` registration proves nothing; without the key the `202` path answers `503 SENDER_UNAVAILABLE` and ordinary pushes are lost silently |
| Q3 | notification, order | A visible push carries no data, and only the notary's liability statement is sent today. Routing a tap needs a data field carrying the order's UUID `id` (the templates name `order_number`, which the order read does not accept), and order would have to send notifications at all |
| Q4 | gateway, identity | Which host serves `apple-app-site-association` for Universal Links, AutoFill association and passkeys, and which relying party the buyer app uses |
| Q5 | identity, infrastructure | The mechanism is known (§1.14). Owed before unnamed clients are refused: a client name for the buyer apps (only `courier-app`, `seller-web` and `backoffice` are registered; from that step a request naming no client is `400 CLIENT_REQUIRED`, which would lock both buyer apps out of sign-in and refresh) |
| Q6 | infrastructure, docs-internal | An operations page for reaching a lab from the iOS simulator over TLS (installing the lab CA in the simulator) |
| Q7 | payment | Confirmed from its controllers: no endpoint lists a buyer's top-ups. After the app's data is lost, a pending top-up still counts against the wallet cap but its instructions cannot be found again. Should payment list them? |
| Q8 | kinetix-android | Three defects seen while reading it, each *verified in its source*: (a) its push handler looks for `type`, `challengeId` and `challengeToken`, while notification sends `kind`, `nonce` and `expires_at`, so it never recognises a device challenge; (b) its outbox overwrites a queued profile edit with the latest edit's fields under `profile:{accountId}`, so an earlier unsent field is lost while the cached profile still shows it; (c) it names `CART_ITEM_UPSERT` among outbox operations: safe only if it calls the `PUT` that sets a quantity, never the `POST` that adds |
| Q9 | kinetix-docs | The wallet signing page of IOS-D14. It reads the typed data from the URL fragment, asks the wallet for `eth_signTypedData_v4`, and shows the result as a QR code and as text. It holds no token and calls no Kinetix API |
| Q10 | notification | Push copy exists in Indonesian only and is rendered by the server. With multilingual apps (IOS-D9), does a push follow the buyer's language, and where is that language kept? |
| Q11 | gateway | Are the shared rate budget, the missing `Retry-After` and the 15-second wait intended? The published reference promises a per-address limit, `Retry-After` and 60 seconds. Does the client's address survive the load balancer, so identity's per-address throttles are per client? A gateway `503` can follow a request the service processed, which the refresh rule of §1.7 tolerates and should not have to |
| Q12 | payment | Which zone `instructions.expiresAt` is in; the field is Midtrans' `expiry_time` unconverted |
| Q13 | order, edge | Nothing a buyer can read says a courier has been assigned or has picked up the parcel, while the published page words the tracking condition in exactly those terms |
| Q14 | seal | A published buyer-app contract for verified anonymous reports (the holder runtime's reporter key and report) |
| Q15 | kinetix-docs | The REST reference pins older releases than production runs for the gateway (still Kong), identity, order, review and seal |

---

## 8. Definition of done for a slice

- The contract page and endpoint definitions were read in full, and every documented answer of every endpoint the slice calls is classified and tested, the unknown outcomes first.
- Repositories and view models are covered by tests with hand-written fakes that ran on the Mac and printed a count; what touches a store, the Keychain or the transport also ran on an iOS simulator; each new test was seen red.
- Every state renders: loading, content, empty, each failure, and "could not be checked" where the contract has an unknown.
- Killing the app at any point of the slice loses nothing the buyer was promised, and nothing of one buyer is shown or sent as another's.
- Copy is in the String Catalog in both languages; no text in a view model; VoiceOver labels and Dynamic Type hold.
- No comment, no fake, no hardcoded value, no fallback; `bin/ci` is green.
- §0.2 has an entry: what was built, what was run with its counts and on which runtimes, what was measured, what is owed.
