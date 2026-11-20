import Foundation
import KinetixDomain
import Observation

@Observable
public final class AccountHomeViewModel {
    public private(set) var state: AccountHomeState = .idle
    public let session: AuthSession

    private let authRepository: any AuthRepository
    private var activeTask: Task<Void, Never>?

    public init(
        session: AuthSession,
        authRepository: any AuthRepository,
    ) {
        self.session = session
        self.authRepository = authRepository
    }

    public func signOut() {
        guard state == .idle else {
            return
        }

        state = .signingOut
        activeTask?.cancel()
        activeTask = Task {
            _ = await authRepository.signOut()
            state = .signedOut
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }
}
