import SwiftUI

@main
struct PortfolioApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView(appState: appState)
                .environment(appState)
        }
    }
}
