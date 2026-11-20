import Foundation
import KinetixData
import Testing

struct WireTimestampTests {
    @Test(
        arguments: [
            "2026-11-16T03:18:05Z",
            "2026-10-27T03:15:00.274Z",
            "2026-10-22T03:25:00.481236Z",
            "2026-10-22T03:15:07.4829137Z",
        ]
    )
    func parsesAllRFC3339FractionalSecondPrecisions(_ sample: String) {
        let parsed = WireTimestamp.parseRFC3339(sample)
        #expect(parsed != nil)
    }

    @Test
    func rejectsMalformedTimestamps() {
        #expect(WireTimestamp.parseRFC3339("") == nil)
        #expect(WireTimestamp.parseRFC3339("2026-10-23 10:15:00") == nil)
        #expect(WireTimestamp.parseRFC3339("not-a-timestamp") == nil)
    }
}
