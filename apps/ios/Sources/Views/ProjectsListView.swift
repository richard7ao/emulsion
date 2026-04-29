import SwiftUI

struct ProjectsListView: View {
    @State private var viewModel: ProjectsViewModel
    @State private var selectedProject: Project?
    @Environment(AppState.self) private var appState

    init(apiClient: any APIClientProtocol) {
        _viewModel = State(initialValue: ProjectsViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.projects.enumerated()), id: \.element.id) { index, project in
                        ProjectCardView(project: project, index: index, baseURL: viewModel.apiClient.baseURL)
                            .padding(.horizontal, EmulsionTheme.cardPadding)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                }
                .padding(.top, EmulsionTheme.cardPadding)
            }
        }
        .background(EmulsionTheme.background)
        .navigationTitle("Projects")
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(apiClient: viewModel.apiClient, projectId: project.id, appState: appState)
        }
        .task {
            await viewModel.load()
        }
    }
}

private struct ProjectCardView: View {
    let project: Project
    let index: Int
    let baseURL: URL

    private var screenshots: [String] {
        parseJSONArray(project.screenshots)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let first = screenshots.first,
               let url = URL(string: first, relativeTo: baseURL) {
                RemoteImage(url: url, height: 140)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(project.title)
                    .font(EmulsionTheme.headlineFont)
                    .foregroundStyle(EmulsionTheme.textPrimary)

                Text(project.role)
                    .font(.system(size: 13))
                    .foregroundStyle(EmulsionTheme.textSecondary)

                HStack {
                    Label("\(project.viewCount)", systemImage: "eye")
                    Spacer()
                    Label("\(project.interestedCount)", systemImage: "heart")
                }
                .font(EmulsionTheme.captionFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
            }
            .padding(12)
        }
        .background(EmulsionTheme.surface)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
