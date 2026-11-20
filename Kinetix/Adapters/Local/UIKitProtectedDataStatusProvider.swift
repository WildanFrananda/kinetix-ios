import Foundation
import KinetixDomain
import UIKit

struct UIKitProtectedDataStatusProvider: ProtectedDataStatusProvider {
    func isProtectedDataAvailable() -> Bool {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                UIApplication.shared.isProtectedDataAvailable
            }
        }

        return true
    }
}
