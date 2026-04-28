import SwiftUI

struct ProjectsListView: View {
    @State private var viewModel: ProjectsViewModel
    @State private var selectedProject: Project?

    init(apiClient: APIClient) {
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
                            .padding(.horizontal, LapseTheme.cardPadding)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                }
                .padding(.top, LapseTheme.cardPadding)
            }
        }
        .background(LapseTheme.background)
        .navigationTitle("Projects")
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(apiClient: viewModel.apiClient, projectId: project.id)
        }
        .task {
            await viewModel.load()
        }
    }

    private var apiClient: APIClient {
        viewModel.apiClient
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
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LapseTheme.border.opacity(0.3))
                        .overlay { ProgressView() }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(project.title)
                    .font(LapseTheme.headlineFont)
                    .foregroundStyle(LapseTheme.textPrimary)

                Text(project.role)
                    .font(.system(size: 13))
                    .foregroundStyle(LapseTheme.textSecondary)

                HStack {
                    Label("\(project.viewCount)", systemImage: "eye")
                    Spacer()
                    Label("\(project.interestedCount)", systemImage: "heart")
                }
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)
            }
            .padding(12)
        }
        .background(LapseTheme.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
