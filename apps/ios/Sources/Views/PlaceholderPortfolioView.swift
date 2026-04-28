import SwiftUI

struct PlaceholderPortfolioView: View {
    var body: some View {
        VStack(spacing: LapseTheme.sectionSpacing) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundStyle(LapseTheme.border)

            Text("Next Portfolio")
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textSecondary)

            Text("Swipe to add another portfolio")
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LapseTheme.background)
    }
}
