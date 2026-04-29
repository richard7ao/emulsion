import SwiftUI

struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    init(apiClient: any APIClientProtocol, projectId: Int, appState: AppState? = nil) {
        _viewModel = State(initialValue: ProjectDetailViewModel(apiClient: apiClient, projectId: projectId, appState: appState))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let project = viewModel.project {
                    projectContent(project)
                }
            }
            .background(EmulsionTheme.background)
            .grainOverlay()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(EmulsionTheme.accent)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func projectContent(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let screenshots = parseJSONArray(project.screenshots)
            if let first = screenshots.first,
               let url = URL(string: first, relativeTo: appState.apiClient.baseURL) {
                RemoteImage(url: url, height: 220)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(project.title)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(EmulsionTheme.textPrimary)

                Text(project.role)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(EmulsionTheme.accent)

                HStack(spacing: 20) {
                    HStack(spacing: 5) {
                        Image(systemName: "eye")
                        Text("\(project.viewCount) views")
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "heart")
                        Text("\(project.interestedCount) interested")
                    }
                }
                .font(EmulsionTheme.captionFont)
                .foregroundStyle(EmulsionTheme.textSecondary)

                Divider()

                Text(project.writeup)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(EmulsionTheme.textPrimary)
                    .lineSpacing(5)

                Button {
                    Task { await viewModel.markInterested() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.hasMarkedInterested ? "heart.fill" : "heart")
                        Text(viewModel.hasMarkedInterested ? "Interested!" : "I'm Interested")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.hasMarkedInterested ? EmulsionTheme.accent : EmulsionTheme.surface)
                    .foregroundStyle(viewModel.hasMarkedInterested ? .white : EmulsionTheme.accent)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(EmulsionTheme.accent, lineWidth: 1)
                    )
                }
                .disabled(viewModel.hasMarkedInterested)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.hasMarkedInterested)
            }
            .padding(20)
        }
    }
}
