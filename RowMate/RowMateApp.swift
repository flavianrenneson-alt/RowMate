import SwiftUI

@main
struct RowMateApp: App {
    @StateObject private var store = SessionStore()
    @StateObject private var watchConnector = WatchConnector()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(watchConnector)
                .onAppear {
                    watchConnector.sessionStore = store
                }
        }
    }
}
