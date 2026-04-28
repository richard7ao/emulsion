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
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textPrimary)

            Text(experience.role)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)

            Text(experience.dates)
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)

            ForEach(bulletItems, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 6) {
                    Text("·")
                        .foregroundStyle(LapseTheme.accent)
                    Text(bullet)
                        .font(LapseTheme.bodyFont)
                        .foregroundStyle(LapseTheme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .polaroidCard(index: index)
    }
}

func parseJSONArray(_ jsonString: String) -> [String] {
    guard let data = jsonString.data(using: .utf8),
          let array = try? JSONDecoder().decode([String].self, from: data) else {
        return jsonString.isEmpty ? [] : [jsonString]
    }
    return array
}
