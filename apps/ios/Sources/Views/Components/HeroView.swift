import SwiftUI

struct HeroView: View {
    let name: String
    let summary: String
    let photoPath: String?
    let baseURL: URL

    var body: some View {
        VStack(spacing: 12) {
            if let photoPath, let url = URL(string: photoPath, relativeTo: baseURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(EmulsionTheme.border)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(EmulsionTheme.textSecondary)
                        }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            }

            Text(name)
                .font(EmulsionTheme.titleFont)
                .foregroundStyle(EmulsionTheme.textPrimary)

            Text(summary)
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, EmulsionTheme.cardPadding)
        }
        .padding(.vertical, EmulsionTheme.sectionSpacing)
    }
}
