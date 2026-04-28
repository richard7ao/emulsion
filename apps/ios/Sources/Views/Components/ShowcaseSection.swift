import SwiftUI

struct ShowcaseSection: View {
    @Environment(AppState.self) private var appState
    @State private var projects: [Project] = []

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    showcaseCard(project: project, index: index)
                }
            }
            .padding(.horizontal, LapseTheme.cardPadding)
        }
        .task {
            projects = (try? await appState.apiClient.listProjects(portfolioId: 1)) ?? []
        }
    }

    private func showcaseCard(project: Project, index: Int) -> some View {
        let screenshots = parseJSONArray(project.screenshots)
        return VStack(spacing: 8) {
            if let first = screenshots.first,
               let url = URL(string: first, relativeTo: appState.apiClient.baseURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                        .fill(LapseTheme.border.opacity(0.3))
                        .overlay { ProgressView() }
                }
                .frame(width: 200, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: LapseTheme.cornerRadius))
            } else {
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
            }

            Text(project.title)
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)
        }
        .polaroidCard(index: index + 50)
    }
}
