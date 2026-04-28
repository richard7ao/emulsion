import SwiftUI

struct ExperienceCardView: View {
    let experience: Experience
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(experience.company)
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textPrimary)

            Text(experience.role)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)

            Text(experience.dates)
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)

            ForEach(experience.bullets.components(separatedBy: "\n"), id: \.self) { bullet in
                if !bullet.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("·")
                            .foregroundStyle(LapseTheme.accent)
                        Text(bullet)
                            .font(LapseTheme.bodyFont)
                            .foregroundStyle(LapseTheme.textPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .polaroidCard(index: index)
    }
}
