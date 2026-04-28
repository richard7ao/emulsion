import SwiftUI

struct PortfolioHomeView: View {
    @State private var viewModel: PortfolioViewModel
    @Environment(AppState.self) private var appState

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: PortfolioViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let portfolio = viewModel.portfolio {
                    contentView(portfolio)
                }
            }
        }
        .background(LapseTheme.background)
        .grainOverlay()
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func contentView(_ portfolio: Portfolio) -> some View {
        HeroView(
            name: portfolio.name,
            summary: portfolio.summary,
            photoPath: portfolio.photoPath,
            baseURL: appState.apiClient.baseURL
        )

        SectionHeaderView(title: "About")
        Text(portfolio.bio)
            .font(LapseTheme.bodyFont)
            .foregroundStyle(LapseTheme.textPrimary)
            .padding(.horizontal, LapseTheme.cardPadding)
            .polaroidCard(index: 0)
            .padding(.horizontal, LapseTheme.cardPadding)

        SectionHeaderView(title: "Showcase")
        ShowcaseSection()

        SectionHeaderView(title: "Experience")
        ForEach(Array(viewModel.experiences.enumerated()), id: \.element.id) { index, exp in
            ExperienceCardView(experience: exp, index: index + 1)
                .padding(.horizontal, LapseTheme.cardPadding)
                .padding(.bottom, 12)
        }

        SectionHeaderView(title: "Skills")
        ForEach(Array(viewModel.skills.enumerated()), id: \.element.id) { index, skill in
            SkillsCardView(skill: skill, index: index + 10)
                .padding(.horizontal, LapseTheme.cardPadding)
                .padding(.bottom, 12)
        }

        navSection("Projects", destination: ProjectsListView(apiClient: appState.apiClient))
        navSection("FAQs", destination: AskView(apiClient: appState.apiClient))
        navSection("Leave a Note", destination: LeaveNoteView(apiClient: appState.apiClient))

        Spacer().frame(height: LapseTheme.sectionSpacing)
    }

    private func navSection<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(LapseTheme.headlineFont)
                    .foregroundStyle(LapseTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(LapseTheme.textSecondary)
            }
            .padding(LapseTheme.cardPadding)
            .background(LapseTheme.surface)
            .cornerRadius(LapseTheme.cornerRadius)
            .padding(.horizontal, LapseTheme.cardPadding)
            .padding(.top, 8)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(LapseTheme.accent)
            Text(message)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load() }
            }
            .foregroundStyle(LapseTheme.accent)
        }
        .padding(.top, 100)
        .padding(.horizontal, LapseTheme.cardPadding)
    }
}
