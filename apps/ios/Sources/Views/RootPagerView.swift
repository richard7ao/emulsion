import SwiftUI

struct RootPagerView: View {
    @Bindable var appState: AppState

    var body: some View {
        TLDRCardView()
            .background(EmulsionTheme.background)
    }
}
