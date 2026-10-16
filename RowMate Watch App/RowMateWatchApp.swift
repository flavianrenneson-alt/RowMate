import SwiftUI

@main
struct RowMateWatchApp: App {
    @StateObject private var sessionStore = WatchSessionStore()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchHomeView()
            }
            .environmentObject(sessionStore)
        }
    }
}
