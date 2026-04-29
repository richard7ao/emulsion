import SwiftUI

struct PortfolioHomeView: View {
    @State private var viewModel: PortfolioViewModel
    @Environment(AppState.self) private var appState

    init(apiClient: any APIClientProtocol) {
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
        .background(EmulsionTheme.background)
        .grainOverlay()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.togglePortfolioInterest()
                } label: {
                    Image(systemName: appState.portfolioInterested ? "heart.fill" : "heart")
                        .foregroundStyle(appState.portfolioInterested ? EmulsionTheme.accent : EmulsionTheme.textSecondary)
                }
            }
        }
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
            .font(EmulsionTheme.bodyFont)
            .foregroundStyle(EmulsionTheme.textPrimary)
            .padding(.horizontal, EmulsionTheme.cardPadding)
            .polaroidCard(index: 0)
            .padding(.horizontal, EmulsionTheme.cardPadding)

        SectionHeaderView(title: "Showcase")
        ShowcaseSection()

        SectionHeaderView(title: "Experience")
        ForEach(Array(viewModel.experiences.enumerated()), id: \.element.id) { index, exp in
            ExperienceCardView(experience: exp, index: index + 1)
                .padding(.horizontal, EmulsionTheme.cardPadding)
                .padding(.bottom, 12)
        }

        SectionHeaderView(title: "Skills")
        ForEach(Array(viewModel.skills.enumerated()), id: \.element.id) { index, skill in
            SkillsCardView(skill: skill, index: index + 10)
                .padding(.horizontal, EmulsionTheme.cardPadding)
                .padding(.bottom, 12)
        }

        navSection("Projects", destination: ProjectsListView(apiClient: appState.apiClient))
        navSection("FAQs", destination: AskView(apiClient: appState.apiClient))
        navSection("Leave a Note", destination: LeaveNoteView(apiClient: appState.apiClient))

        Spacer().frame(height: EmulsionTheme.sectionSpacing)
    }

    private func navSection<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(EmulsionTheme.headlineFont)
                    .foregroundStyle(EmulsionTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(EmulsionTheme.textSecondary)
            }
            .padding(EmulsionTheme.cardPadding)
            .background(EmulsionTheme.surface)
            .cornerRadius(EmulsionTheme.cornerRadius)
            .padding(.horizontal, EmulsionTheme.cardPadding)
            .padding(.top, 8)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(EmulsionTheme.accent)
            Text(message)
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load() }
            }
            .foregroundStyle(EmulsionTheme.accent)
        }
        .padding(.top, 100)
        .padding(.horizontal, EmulsionTheme.cardPadding)
    }
}
