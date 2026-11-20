import Foundation

public protocol ProfileRepository: Sendable {
    func fetchProfile(
        accountId: AccountId,
        principalId: PrincipalId,
    ) async -> Result<ProfileFetchOutcome, Failure>

    func saveProfile(
        accountId: AccountId,
        principalId: PrincipalId,
        draft: ProfileDraft,
    ) async -> Result<ProfileSaveOutcome, Failure>
}
