import Foundation
import KinetixDomain
import Testing

struct ProfilePatchTests {
    @Test
    func diffsAgainstConfirmedProfileAndOmitsUnchangedFields() throws {
        let accountId = try #require(AccountId(42))
        let confirmed = DeliveryProfile(
            id: 17,
            accountId: accountId,
            fullName: "Siti Rahmawati",
            phoneNumber: "+6281234567890",
            streetAddress: "Jalan Kenanga Raya No. 17",
            city: "Jakarta Selatan",
            postalCode: "12730",
            avatarURL: "https://cdn.example.test/42.jpg",
        )

        var draft = ProfileDraft(profile: confirmed)
        draft.phoneNumber = "+6281999999999"
        draft.avatarURL = ""

        let patch = ProfilePatch.diff(from: confirmed, to: draft)

        #expect(patch.fullName == nil)
        #expect(patch.phoneNumber == "+6281999999999")
        #expect(patch.streetAddress == nil)
        #expect(patch.city == nil)
        #expect(patch.postalCode == nil)
        #expect(patch.avatarUpdate == .remove)
    }

    @Test
    func mergingSequentialPatchesCombinesFieldsAndPreservesAvatarRemoval() {
        let first = ProfilePatch(
            phoneNumber: "+6281111111111",
            avatarUpdate: .remove,
        )
        let second = ProfilePatch(
            streetAddress: "Jalan Melati No. 5",
            avatarUpdate: .unchanged,
        )

        let merged = first.merged(with: second)

        #expect(merged.phoneNumber == "+6281111111111")
        #expect(merged.streetAddress == "Jalan Melati No. 5")
        #expect(merged.avatarUpdate == .remove)
    }
}
