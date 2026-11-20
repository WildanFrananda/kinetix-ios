import BackgroundTasks
import Foundation
import KinetixData
import KinetixDomain
import UIKit

final class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    static let outboxRefreshIdentifier = "com.kinetix.shop.outbox-refresh"

    var onBackgroundOutboxRefresh: (@Sendable () async -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.outboxRefreshIdentifier,
            using: nil,
        ) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            self?.handleOutboxRefresh(refreshTask)
        }

        return true
    }

    private func handleOutboxRefresh(_ task: BGAppRefreshTask) {
        let handler = onBackgroundOutboxRefresh
        let work = Task {
            if let handler {
                await handler()
            }

            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
        }
    }
}
