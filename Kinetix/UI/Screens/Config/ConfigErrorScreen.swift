import KinetixDomain
import SwiftUI

struct ConfigErrorScreen: View {
    let issues: [AppConfigIssue]

    var body: some View {
        ConfigErrorContent(issues: issues)
    }
}
