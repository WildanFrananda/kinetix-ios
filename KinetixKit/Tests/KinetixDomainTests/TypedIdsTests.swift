import Foundation
import KinetixDomain
import Testing

struct TypedIdsTests {
    @Test
    func accountIdRejectsZeroNegativeAndOverflow() {
        #expect(AccountId(0) == nil)
        #expect(AccountId(-5) == nil)
        #expect(AccountId(Int(Int32.max) + 1) == nil)
        #expect(AccountId(1)?.value == 1)
        #expect(AccountId(42)?.value == 42)
    }

    @Test
    func principalIdRequiresValidUUIDAndNormalizesLowercase() {
        #expect(PrincipalId("not-a-uuid") == nil)
        #expect(PrincipalId("") == nil)

        let raw = "0F8B6C1E-5A2D-4C3B-9E7F-1A2B3C4D5E6F"
        let principal = PrincipalId(raw)
        #expect(principal?.value == raw.lowercased())
    }

    @Test
    func idempotencyKeyValidatesLengthAndCharacterSet() {
        #expect(IdempotencyKey("") == nil)
        #expect(IdempotencyKey("has space") == nil)
        #expect(IdempotencyKey(String(repeating: "a", count: 101)) == nil)
        #expect(IdempotencyKey("order:123-abc_4.5")?.value == "order:123-abc_4.5")
        #expect(!IdempotencyKey.generate().value.isEmpty)
    }
}
