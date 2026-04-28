import SwiftUI

struct TLDRCardView: View {
    @State private var portfolio: Portfolio?
    @State private var isLoading = true
    @State private var showFullProfile = false
    @State private var isInterested = false
    @State private var interestCount = 0
    @State private var viewCount = 0
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                LapseTheme.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if let portfolio {
                    cardContent(portfolio)
                }
            }
            .grainOverlay()
            .navigationDestination(isPresented: $showFullProfile) {
                PortfolioHomeView(apiClient: appState.apiClient)
            }
        }
        .task {
            do {
                let response = try await appState.apiClient.getPortfolio(id: 1)
                portfolio = response.portfolio
                interestCount = response.portfolio.interestedCount
                viewCount = response.portfolio.viewCount
                _ = try? await appState.apiClient.postPortfolioView(id: 1)
                viewCount += 1
            } catch {}
            isLoading = false
        }
    }

    private func cardContent(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                if let photoPath = portfolio.photoPath,
                   let url = URL(string: photoPath, relativeTo: appState.apiClient.baseURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(LapseTheme.border)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(LapseTheme.textSecondary)
                            }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                }

                Text(portfolio.name)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundStyle(LapseTheme.textPrimary)
                    .padding(.bottom, 4)

                Text(portfolio.summary)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(LapseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)

                Text(portfolio.bio)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(LapseTheme.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                HStack(spacing: 24) {
                    Button {
                        guard !isInterested else { return }
                        isInterested = true
                        interestCount += 1
                        Task {
                            _ = try? await appState.apiClient.postPortfolioInterested(id: portfolio.id)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isInterested ? "heart.fill" : "heart")
                                .foregroundStyle(isInterested ? LapseTheme.accent : LapseTheme.textSecondary)
                            Text("\(interestCount)")
                                .font(LapseTheme.captionFont)
                                .foregroundStyle(LapseTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: isInterested)

                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .foregroundStyle(LapseTheme.textSecondary)
                        Text("\(viewCount)")
                            .font(LapseTheme.captionFont)
                            .foregroundStyle(LapseTheme.textSecondary)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(LapseTheme.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 28)
            .onTapGesture {
                showFullProfile = true
            }

            Spacer()

            Text("Tap to view full profile")
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)
                .padding(.bottom, 32)
        }
    }
}
