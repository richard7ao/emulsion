import SwiftUI

struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(apiClient: APIClient, projectId: Int) {
        _viewModel = State(initialValue: ProjectDetailViewModel(apiClient: apiClient, projectId: projectId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let project = viewModel.project {
                    VStack(alignment: .leading, spacing: LapseTheme.cardPadding) {
                        Text(project.title)
                            .font(LapseTheme.titleFont)
                            .foregroundStyle(LapseTheme.textPrimary)

                        Text(project.role)
                            .font(LapseTheme.headlineFont)
                            .foregroundStyle(LapseTheme.textSecondary)

                        HStack {
                            Label("\(project.viewCount) views", systemImage: "eye")
                            Spacer()
                            Label("\(project.interestedCount) interested", systemImage: "heart")
                        }
                        .font(LapseTheme.captionFont)
                        .foregroundStyle(LapseTheme.textSecondary)

                        Text(project.writeup)
                            .font(LapseTheme.bodyFont)
                            .foregroundStyle(LapseTheme.textPrimary)

                        Button {
                            Task { await viewModel.markInterested() }
                        } label: {
                            HStack {
                                Image(systemName: viewModel.hasMarkedInterested ? "heart.fill" : "heart")
                                Text(viewModel.hasMarkedInterested ? "Interested!" : "I'm Interested")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.hasMarkedInterested ? LapseTheme.accent : LapseTheme.surface)
                            .foregroundStyle(viewModel.hasMarkedInterested ? .white : LapseTheme.accent)
                            .cornerRadius(LapseTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                                    .stroke(LapseTheme.accent, lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.hasMarkedInterested)
                    }
                    .padding(LapseTheme.cardPadding)
                }
            }
            .background(LapseTheme.background)
            .grainOverlay()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LapseTheme.accent)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
