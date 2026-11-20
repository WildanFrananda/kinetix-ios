import Foundation
import KinetixDomain
import Observation

@Observable
public final class ProfileViewModel {
    public var draft = ProfileDraft()
    public private(set) var state: ProfileScreenState = .idle
    public private(set) var saveState: ProfileSaveState = .idle

    private let accountId: AccountId
    private let principalId: PrincipalId
    private let repository: any ProfileRepository
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    public init(
        accountId: AccountId,
        principalId: PrincipalId,
        repository: any ProfileRepository,
    ) {
        self.accountId = accountId
        self.principalId = principalId
        self.repository = repository
    }

    public func start() {
        switch state {
        case .idle, .failed:
            load(showLoadingState: true)
        case .loading, .notCreated, .loaded, .cachedStale, .pendingLocalSync:
            break
        }
    }

    public func refresh() {
        load(showLoadingState: !hasHeldContent)
    }

    public func save() {
        let currentDraft = draft
        saveTask?.cancel()
        saveState = .saving

        saveTask = Task {
            let result = await repository.saveProfile(
                accountId: accountId,
                principalId: principalId,
                draft: currentDraft,
            )
            switch result {
            case .success(.confirmed(let profile)):
                draft = ProfileDraft(profile: profile)
                state = .loaded(profile)
                saveState = .savedConfirmed
            case .success(.queuedOffline(let profile)):
                draft = ProfileDraft(profile: profile)
                state = .pendingLocalSync(profile)
                saveState = .savedLocallyPendingSync
            case .failure(.cancelled):
                saveState = .idle
            case .failure(let failure):
                saveState = .failed(failure)
            }
        }
    }

    public func cancel() {
        loadTask?.cancel()
        saveTask?.cancel()
    }

    private var hasHeldContent: Bool {
        switch state {
        case .notCreated, .loaded, .cachedStale, .pendingLocalSync:
            return true
        case .idle, .loading, .failed:
            return false
        }
    }

    private func load(showLoadingState: Bool) {
        loadTask?.cancel()
        if showLoadingState {
            state = .loading
        }

        loadTask = Task {
            let result = await repository.fetchProfile(
                accountId: accountId,
                principalId: principalId,
            )
            switch result {
            case .success(.notCreated):
                state = .notCreated
            case .success(.confirmed(let profile)):
                draft = ProfileDraft(profile: profile)
                state = .loaded(profile)
            case .success(.cachedStale(let profile)):
                draft = ProfileDraft(profile: profile)
                state = .cachedStale(profile)
            case .success(.pendingLocalSync(let profile)):
                draft = ProfileDraft(profile: profile)
                state = .pendingLocalSync(profile)
            case .failure(.cancelled):
                break
            case .failure(let failure):
                if !hasHeldContent {
                    state = .failed(failure)
                }
            }
        }
    }
}
