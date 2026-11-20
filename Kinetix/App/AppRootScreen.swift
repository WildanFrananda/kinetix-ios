import KinetixDomain
import KinetixPresentation
import SwiftUI

struct AppRootScreen: View {
    @State private var viewModel: AppRootViewModel
    @Bindable private var router: AppRouter
    @Bindable private var languageSettings: LanguageSettingsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var systemLocale

    private let container: AppContainer

    init(
        viewModel: AppRootViewModel,
        container: AppContainer,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.router = container.router
        self.languageSettings = container.languageSettingsViewModel
        self.container = container
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .validating, .configured, .checkingSession:
                VStack(spacing: KinetixTheme.spacingMedium) {
                    ProgressView()
                        .tint(KinetixPalette.accent)

                    Text(.startupValidatingLabel)
                        .font(KinetixTypography.body)
                        .foregroundStyle(KinetixPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(KinetixPalette.background.ignoresSafeArea())
            case .invalidConfiguration(let issues):
                ConfigErrorScreen(issues: issues)
            case .sessionCheckFailed(_, let failure):
                VStack(spacing: KinetixTheme.spacingLarge) {
                    KinetixStatusBanner(
                        tone: .warning,
                        message: container.failureMapper.message(for: failure),
                    )

                    KinetixPrimaryButton(
                        title: .commonRetryButton,
                        action: viewModel.retrySessionCheck,
                    )
                }
                .padding(KinetixTheme.spacingLarge)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(KinetixPalette.background.ignoresSafeArea())
            case .signedOut(let config):
                NavigationStack(path: $router.path) {
                    CatalogHomeScreen(
                        viewModel: container.makeCatalogHomeViewModel(config: config),
                        isAuthenticated: false,
                        failureMapper: container.failureMapper,
                        imagePipeline: container.imagePipeline(for: config),
                        onOpenSearch: {
                            router.navigate(to: .search, isAuthenticated: false)
                        },
                        onOpenLanguageSettings: {
                            router.navigate(to: .languageSettings, isAuthenticated: false)
                        },
                        onOpenAccountOrSignIn: {
                            router.navigate(to: .signIn, isAuthenticated: false)
                        },
                        onSelectProduct: { sku in
                            router.navigate(to: .productDetail(sku), isAuthenticated: false)
                        },
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(route: route, config: config, session: nil)
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
            case .signedIn(let config, let session):
                NavigationStack(path: $router.path) {
                    CatalogHomeScreen(
                        viewModel: container.makeCatalogHomeViewModel(config: config),
                        isAuthenticated: true,
                        failureMapper: container.failureMapper,
                        imagePipeline: container.imagePipeline(for: config),
                        onOpenSearch: {
                            router.navigate(to: .search, isAuthenticated: true)
                        },
                        onOpenLanguageSettings: {
                            router.navigate(to: .languageSettings, isAuthenticated: true)
                        },
                        onOpenAccountOrSignIn: {
                            router.navigate(to: .account, isAuthenticated: true)
                        },
                        onSelectProduct: { sku in
                            router.navigate(to: .productDetail(sku), isAuthenticated: true)
                        },
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(route: route, config: config, session: session)
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
            }
        }
        .environment(
            \.locale,
            languageSettings.activeLocaleOverride ?? systemLocale,
        )
        .task {
            viewModel.start()
        }
        .onChange(of: router.path) { _, _ in
            router.persistCurrentPath()
        }
        .onChange(of: scenePhase) { _, nextPhase in
            switch nextPhase {
            case .active:
                viewModel.onBecomeActive()
            case .background:
                if case .signedIn(let config, let session) = viewModel.state {
                    container.scheduleBackgroundOutboxRefreshIfNeeded(
                        config: config,
                        principalId: session.user.principalId,
                    )
                }
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    @ViewBuilder
    private func destination(
        route: AppRoute,
        config: AppConfig,
        session: AuthSession?,
    ) -> some View {
        let isAuthenticated = session != nil

        switch route {
        case .search:
            SearchScreen(
                viewModel: container.makeSearchViewModel(config: config),
                failureMapper: container.failureMapper,
                onSelectProduct: { sku in
                    router.navigate(
                        to: .productDetail(sku),
                        isAuthenticated: isAuthenticated,
                    )
                },
            )
        case .productDetail(let sku):
            ProductDetailScreen(
                viewModel: container.makeProductDetailViewModel(
                    config: config,
                    sku: sku,
                ),
                failureMapper: container.failureMapper,
                imagePipeline: container.imagePipeline(for: config),
            )
        case .languageSettings:
            LanguageSettingsScreen(
                viewModel: languageSettings
            )
        case .signIn:
            SignInScreen(
                viewModel: container.makeSignInViewModel(config: config),
                failureMapper: container.failureMapper,
                onSignedIn: { signedInSession in
                    router.restoreSession(for: signedInSession.user.principalId)
                    viewModel.didSignIn(signedInSession)
                },
                onTwoFactorRequired: { challenge in
                    router.beginTwoFactorChallenge(challenge)
                },
                onNavigateRegister: {
                    router.navigate(to: .register, isAuthenticated: false)
                },
            )
        case .register:
            RegisterScreen(
                viewModel: container.makeRegisterViewModel(config: config),
                failureMapper: container.failureMapper,
                onRegistered: { registeredSession in
                    router.restoreSession(for: registeredSession.user.principalId)
                    viewModel.didSignIn(registeredSession)
                },
            )
        case .twoFactorChallenge:
            if let challenge = router.activeChallenge {
                TwoFactorChallengeScreen(
                    viewModel: container.makeTwoFactorChallengeViewModel(
                        config: config,
                        challenge: challenge,
                    ),
                    failureMapper: container.failureMapper,
                    onVerified: { verifiedSession in
                        router.restoreSession(for: verifiedSession.user.principalId)
                        viewModel.didSignIn(verifiedSession)
                    },
                    onReturnToSignIn: {
                        router.popToRoot()
                    },
                )
            } else {
                SignInScreen(
                    viewModel: container.makeSignInViewModel(config: config),
                    failureMapper: container.failureMapper,
                    onSignedIn: { signedInSession in
                        router.restoreSession(for: signedInSession.user.principalId)
                        viewModel.didSignIn(signedInSession)
                    },
                    onTwoFactorRequired: { challenge in
                        router.beginTwoFactorChallenge(challenge)
                    },
                    onNavigateRegister: {
                        router.navigate(to: .register, isAuthenticated: false)
                    },
                )
            }
        case .account:
            if let session {
                AccountHomeScreen(
                    viewModel: container.makeAccountHomeViewModel(
                        config: config,
                        session: session,
                    ),
                    selectedLanguage: languageSettings.selectedLanguage,
                    onOpenProfile: {
                        router.navigate(to: .profile, isAuthenticated: true)
                    },
                    onOpenTwoFactor: {
                        router.navigate(to: .twoFactorSettings, isAuthenticated: true)
                    },
                    onOpenLanguageSettings: {
                        router.navigate(to: .languageSettings, isAuthenticated: true)
                    },
                    onSignedOut: {
                        router.clearSession(for: session.user.principalId)
                        viewModel.didSignOut()
                    },
                )
            } else {
                EmptyView()
            }
        case .profile:
            if let session {
                ProfileScreen(
                    viewModel: container.makeProfileViewModel(
                        config: config,
                        accountId: session.user.accountId,
                        principalId: session.user.principalId,
                    ),
                    failureMapper: container.failureMapper,
                )
            } else {
                EmptyView()
            }
        case .twoFactorSettings:
            if let session {
                TwoFactorSettingsScreen(
                    viewModel: container.makeTwoFactorSettingsViewModel(
                        config: config,
                        accountId: session.user.accountId,
                    ),
                    failureMapper: container.failureMapper,
                )
            } else {
                EmptyView()
            }
        }
    }
}
