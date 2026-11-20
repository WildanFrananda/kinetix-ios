import Foundation
import SwiftData

extension TripwireLedgerV1 {
    @Model
    final class TripwireRow {
        #Unique<TripwireRow>([\.key])

        var key: String
        var payload: String

        init(
            key: String,
            payload: String,
        ) {
            self.key = key
            self.payload = payload
        }
    }
}
