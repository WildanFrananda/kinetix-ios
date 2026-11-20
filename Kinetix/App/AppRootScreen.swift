import KinetixDomain
import KinetixPresentation
import SwiftUI

struct AppRootScreen: View {
    @State private var viewModel: AppRootViewModel
    @Bindable private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    private let container: AppContainer

    init(
        viewModel: AppRootViewModel,
        container: AppContainer,
    ) {
        _viewModel = State(initialValue: viewModel)
        self.router = container.router
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
                    SignInScreen(
                        viewModel: container.makeSignInViewModel(config: config),
                        failureMapper: container.failureMapper,
                        onSignedIn: { session in
                            router.restoreSession(for: session.user.principalId)
                            viewModel.didSignIn(session)
                        },
                        onTwoFactorRequired: { challenge in
                            router.beginTwoFactorChallenge(challenge)
                        },
                        onNavigateRegister: {
                            router.navigate(to: .register, isAuthenticated: false)
                        },
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        unauthenticatedDestination(route: route, config: config)
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
            case .signedIn(let config, let session):
                NavigationStack(path: $router.path) {
                    AccountHomeScreen(
                        viewModel: container.makeAccountHomeViewModel(
                            config: config,
                            session: session,
                        ),
                        onOpenProfile: {
                            router.navigate(to: .profile, isAuthenticated: true)
                        },
                        onOpenTwoFactor: {
                            router.navigate(to: .twoFactorSettings, isAuthenticated: true)
                        },
                        onSignedOut: {
                            router.clearSession(for: session.user.principalId)
                            viewModel.didSignOut()
                        },
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        authenticatedDestination(
                            route: route,
                            config: config,
                            session: session,
                        )
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
            }
        }
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
    private func unauthenticatedDestination(
        route: AppRoute,
        config: AppConfig,
    ) -> some View {
        switch route {
        case .register:
            RegisterScreen(
                viewModel: container.makeRegisterViewModel(config: config),
                failureMapper: container.failureMapper,
                onRegistered: { session in
                    router.restoreSession(for: session.user.principalId)
                    viewModel.didSignIn(session)
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
                    onVerified: { session in
                        router.restoreSession(for: session.user.principalId)
                        viewModel.didSignIn(session)
                    },
                    onReturnToSignIn: {
                        router.popToRoot()
                    },
                )
            } else {
                SignInScreen(
                    viewModel: container.makeSignInViewModel(config: config),
                    failureMapper: container.failureMapper,
                    onSignedIn: { session in
                        router.restoreSession(for: session.user.principalId)
                        viewModel.didSignIn(session)
                    },
                    onTwoFactorRequired: { challenge in
                        router.beginTwoFactorChallenge(challenge)
                    },
                    onNavigateRegister: {
                        router.navigate(to: .register, isAuthenticated: false)
                    },
                )
            }
        case .profile, .twoFactorSettings:
            EmptyView()
        }
    }

    @ViewBuilder
    private func authenticatedDestination(
        route: AppRoute,
        config: AppConfig,
        session: AuthSession,
    ) -> some View {
        switch route {
        case .profile:
            ProfileScreen(
                viewModel: container.makeProfileViewModel(
                    config: config,
                    accountId: session.user.accountId,
                    principalId: session.user.principalId,
                ),
                failureMapper: container.failureMapper,
            )
        case .twoFactorSettings:
            TwoFactorSettingsScreen(
                viewModel: container.makeTwoFactorSettingsViewModel(
                    config: config,
                    accountId: session.user.accountId,
                ),
                failureMapper: container.failureMapper,
            )
        case .register, .twoFactorChallenge:
            EmptyView()
        }
    }
}
