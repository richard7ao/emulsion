import SwiftUI

struct ShowcaseSection: View {
    @Environment(AppState.self) private var appState
    @State private var projects: [Project] = []
    @State private var selectedProject: Project?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    showcaseCard(project: project, index: index)
                        .onTapGesture {
                            selectedProject = project
                        }
                }
            }
            .padding(.horizontal, EmulsionTheme.cardPadding)
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(apiClient: appState.apiClient, projectId: project.id, appState: appState)
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
                RemoteImage(url: url, height: 140, width: 200)
                    .clipShape(RoundedRectangle(cornerRadius: EmulsionTheme.cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: EmulsionTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [EmulsionTheme.accent.opacity(0.15), EmulsionTheme.border.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 140)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(EmulsionTheme.textSecondary.opacity(0.5))
                    }
            }

            Text(project.title)
                .font(EmulsionTheme.captionFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
        }
        .polaroidCard(index: index + 50)
    }
}
