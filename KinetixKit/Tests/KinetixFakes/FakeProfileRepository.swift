import Foundation
import KinetixDomain
import Synchronization

public final class FakeProfileRepository: ProfileRepository {
    private let state = Mutex<
        (
            fetchResult: Result<ProfileFetchOutcome, Failure>,
            saveResult: Result<ProfileSaveOutcome, Failure>,
            fetchCount: Int,
            saveCount: Int,
        )
    >(
        (
            fetchResult: .success(.notCreated),
            saveResult: .failure(.networkNotSent),
            fetchCount: 0,
            saveCount: 0,
        )
    )

    public init() {}

    public func setFetchResult(_ result: Result<ProfileFetchOutcome, Failure>) {
        state.withLock { $0.fetchResult = result }
    }

    public func setSaveResult(_ result: Result<ProfileSaveOutcome, Failure>) {
        state.withLock { $0.saveResult = result }
    }

    public func fetchCount() -> Int {
        return state.withLock { $0.fetchCount }
    }

    public func fetchProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<ProfileFetchOutcome, Failure> {
        return state.withLock { current in
            current.fetchCount += 1
            return current.fetchResult
        }
    }

    public func saveProfile(
        accountId: AccountId,
        principalId: PrincipalId,
        draft: ProfileDraft,
    ) async -> Result<ProfileSaveOutcome, Failure> {
        return state.withLock { current in
            current.saveCount += 1
            return current.saveResult
        }
    }
}
