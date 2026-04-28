import SwiftUI

struct TLDRCardView: View {
    @State private var portfolio: Portfolio?
    @State private var isLoading = true
    @Environment(AppState.self) private var appState
    @State private var showFullProfile = false

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
            } catch {}
            isLoading = false
        }
    }

    private func cardContent(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
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
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                }

                VStack(spacing: 8) {
                    Text(portfolio.name)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(LapseTheme.textPrimary)

                    Text(portfolio.summary)
                        .font(LapseTheme.bodyFont)
                        .foregroundStyle(LapseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Text(portfolio.bio)
                    .font(LapseTheme.bodyFont)
                    .foregroundStyle(LapseTheme.textPrimary)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
            }
            .padding(LapseTheme.sectionSpacing)
            .padding(.horizontal, 8)
            .background(LapseTheme.surface)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
            .onTapGesture {
                showFullProfile = true
            }

            Spacer()

            Text("Tap to view full profile")
                .font(LapseTheme.captionFont)
                .foregroundStyle(LapseTheme.textSecondary)
                .padding(.bottom, 40)
        }
    }
}
