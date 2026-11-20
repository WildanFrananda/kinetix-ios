import Foundation
import KinetixDomain

public struct IdentityAPIClient: Sendable {
    public static let logoutTimeoutSeconds: TimeInterval = 5

    private let apiCaller: SafeApiCaller
    private let clock: any AppClock

    public init(
        apiCaller: SafeApiCaller,
        clock: any AppClock,
    ) {
        self.apiCaller = apiCaller
        self.clock = clock
    }

    public func login(
        email: String,
        password: String,
    ) async -> Result<SignInOutcome, Failure> {
        let dto = LoginRequestDTO(email: email, password: password)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/login",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: false,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    LoginResponseDTO.self,
                    from: response.body,
                )
            else {
                return .failure(.unreadableResponse)
            }

            return decoded.toDomain(issuedAt: clock.now())
        }
    }

    public func register(
        email: String,
        password: String,
    ) async -> Result<AuthSession, Failure> {
        let dto = RegisterRequestDTO(email: email, password: password)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/register",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: false,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    AuthSessionResponseDTO.self,
                    from: response.body,
                ),
                let session = decoded.toDomain(issuedAt: clock.now())
            else {
                return .failure(.unreadableResponse)
            }

            return .success(session)
        }
    }

    public func verifyTwoFactor(
        challengeToken: String,
        code: String,
    ) async -> Result<AuthSession, Failure> {
        let dto = VerifyTwoFactorRequestDTO(challengeToken: challengeToken, code: code)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/2fa/verify",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: false,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    AuthSessionResponseDTO.self,
                    from: response.body,
                ),
                let session = decoded.toDomain(issuedAt: clock.now())
            else {
                return .failure(.unreadableResponse)
            }

            return .success(session)
        }
    }

    public func fetchMe() async -> Result<SessionCheckResult, Failure> {
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/auth/me",
            isWrite: false,
            hasOwnUnauthorized: false,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    AuthMeResponseDTO.self,
                    from: response.body,
                ),
                let result = decoded.toDomain()
            else {
                return .failure(.unreadableResponse)
            }

            return .success(result)
        }
    }

    public func logout(refreshToken: String) async -> Result<Void, Failure> {
        guard let body = try? JSONEncoder().encode(LogoutRequestDTO(refreshToken: refreshToken))
        else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/logout",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: true,
            timeoutSeconds: Self.logoutTimeoutSeconds,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success:
            return .success(())
        }
    }

    public func setupTwoFactor(
        accountId: AccountId,
        password: String,
    ) async -> Result<TwoFactorSetup, Failure> {
        let dto = TwoFactorSetupRequestDTO(password: password)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/2fa/setup/\(accountId.value)",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    TwoFactorSetupResponseDTO.self,
                    from: response.body,
                )
            else {
                return .failure(.unreadableResponse)
            }

            return .success(decoded.toDomain())
        }
    }

    public func enableTwoFactor(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        let dto = TwoFactorEnableRequestDTO(code: code, password: password)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/2fa/enable/\(accountId.value)",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    TwoFactorStatusResponseDTO.self,
                    from: response.body,
                )
            else {
                return .failure(.unreadableResponse)
            }

            return .success(decoded.toDomain())
        }
    }

    public func disableTwoFactor(
        accountId: AccountId,
        code: String,
        password: String,
    ) async -> Result<TwoFactorStatus, Failure> {
        let dto = TwoFactorDisableRequestDTO(code: code, password: password)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .post,
            path: "/api/v1/auth/2fa/disable/\(accountId.value)",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: true,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    TwoFactorStatusResponseDTO.self,
                    from: response.body,
                )
            else {
                return .failure(.unreadableResponse)
            }

            return .success(decoded.toDomain())
        }
    }

    public func fetchProfile(accountId: AccountId) async -> Result<DeliveryProfile, Failure> {
        let request = HTTPRequest(
            method: .get,
            path: "/api/v1/users/\(accountId.value)/profile",
            isWrite: false,
            hasOwnUnauthorized: false,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    ProfileResponseDTO.self,
                    from: response.body,
                ),
                let profile = decoded.toDomain()
            else {
                return .failure(.unreadableResponse)
            }

            return .success(profile)
        }
    }

    public func updateProfile(
        accountId: AccountId,
        patch: ProfilePatch,
    ) async -> Result<DeliveryProfile, Failure> {
        let dto = UpdateProfileRequestDTO(patch: patch)
        guard let body = try? JSONEncoder().encode(dto) else {
            return .failure(.validation(ValidationFailure()))
        }

        let request = HTTPRequest(
            method: .put,
            path: "/api/v1/users/\(accountId.value)/profile",
            body: body,
            isWrite: true,
            hasOwnUnauthorized: false,
            requiresAuth: true,
        )

        switch await apiCaller.execute(request) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let response):
            guard
                let decoded = try? JSONDecoder().decode(
                    ProfileResponseDTO.self,
                    from: response.body,
                ),
                let profile = decoded.toDomain()
            else {
                return .failure(.unreadableResponse)
            }

            return .success(profile)
        }
    }
}
