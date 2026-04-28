import SwiftUI

struct ShowcaseSection: View {
    private let items = ["Project 1", "Project 2", "Project 3"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, title in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [LapseTheme.accent.opacity(0.15), LapseTheme.border.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 140)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundStyle(LapseTheme.textSecondary.opacity(0.5))
                            }

                        Text(title)
                            .font(LapseTheme.captionFont)
                            .foregroundStyle(LapseTheme.textSecondary)
                    }
                    .polaroidCard(index: index + 50)
                }
            }
            .padding(.horizontal, LapseTheme.cardPadding)
        }
    }
}
