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
                        ProjectCardView(project: project, index: index)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.title)
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textPrimary)

            Text(project.role)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)

            HStack {
                Label("\(project.viewCount)", systemImage: "eye")
                Spacer()
                Label("\(project.interestedCount)", systemImage: "heart")
            }
            .font(LapseTheme.captionFont)
            .foregroundStyle(LapseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .polaroidCard(index: index)
    }
}
