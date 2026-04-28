import SwiftUI

struct RootPagerView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView(selection: $appState.currentPortfolioIndex) {
            ContentView()
                .tag(0)

            PlaceholderPortfolioView()
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(LapseTheme.background)
    }
}
