import SwiftUI
import Foundation

struct ExperienceCardView: View {
    let experience: Experience
    let index: Int

    private var bulletItems: [String] {
        parseJSONArray(experience.bullets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(experience.company)
                .font(EmulsionTheme.headlineFont)
                .foregroundStyle(EmulsionTheme.textPrimary)

            Text(experience.role)
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)

            Text(experience.dates)
                .font(EmulsionTheme.captionFont)
                .foregroundStyle(EmulsionTheme.textSecondary)

            ForEach(bulletItems, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 6) {
                    Text("·")
                        .foregroundStyle(EmulsionTheme.accent)
                    Text(bullet)
                        .font(EmulsionTheme.bodyFont)
                        .foregroundStyle(EmulsionTheme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .polaroidCard(index: index)
    }
}
