import SwiftUI

struct MainTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            RootPagerView(appState: appState)
                .tabItem {
                    Image(systemName: "square.stack.fill")
                    Text("Cards")
                }
                .tag(0)

            NavigationStack {
                InboxView(apiClient: appState.apiClient)
            }
                .tabItem {
                    Image(systemName: "tray.fill")
                    Text("Inbox")
                }
                .tag(1)
        }
        .tint(EmulsionTheme.accent)
    }
}
