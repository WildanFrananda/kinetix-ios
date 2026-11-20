import Foundation
import SwiftData

extension TripwireLedgerV2 {
    @Model
    final class TripwireRow {
        #Unique<TripwireRow>([\.key])

        var key: String
        var payload: String
        var migratedFlag: Bool = true

        init(
            key: String,
            payload: String,
            migratedFlag: Bool = true,
        ) {
            self.key = key
            self.payload = payload
            self.migratedFlag = migratedFlag
        }
    }
}
