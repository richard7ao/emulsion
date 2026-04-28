import SwiftUI

struct TLDRCardView: View {
    @State private var portfolio: Portfolio?
    @State private var isLoading = true
    @State private var showFullProfile = false
    @State private var dragOffset: CGSize = .zero
    @State private var swipeResult: SwipeResult? = nil
    @Environment(AppState.self) private var appState

    enum SwipeResult {
        case accepted, rejected
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LapseTheme.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if let portfolio {
                    if let result = swipeResult {
                        swipeOverlay(result)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    } else {
                        cardContent(portfolio)
                            .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
                            .rotationEffect(.degrees(Double(dragOffset.width / 25)))
                            .overlay {
                                stampOverlay
                            }
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded(handleSwipe)
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
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
                appState.portfolioInterestCount = response.portfolio.interestedCount
                appState.portfolioViewCount = response.portfolio.viewCount
                _ = try? await appState.apiClient.postPortfolioView(id: 1)
                appState.portfolioViewCount += 1
            } catch {}
            isLoading = false
        }
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let threshold: CGFloat = 130
        let pastThreshold = abs(value.translation.width) > threshold
        let isRight = value.translation.width > 0

        guard pastThreshold else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                dragOffset = .zero
            }
            return
        }

        withAnimation(.easeOut(duration: 0.35)) {
            dragOffset = CGSize(
                width: isRight ? 600 : -600,
                height: value.translation.height * 2
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dragOffset = .zero
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                swipeResult = isRight ? .accepted : .rejected
            }
        }
    }

    @ViewBuilder
    private var stampOverlay: some View {
        let offset = dragOffset.width
        if abs(offset) > 30 {
            let isRight = offset > 0
            VStack {
                Spacer().frame(height: 80)
                HStack {
                    if !isRight { Spacer() }
                    stampLabel(
                        isRight ? "HIRE" : "NOPE",
                        color: isRight ? .green : .red,
                        rotation: isRight ? -20 : 20
                    )
                    .opacity(min(Double(abs(offset) - 30) / 120, 1))
                    .padding(isRight ? .leading : .trailing, 50)
                    if isRight { Spacer() }
                }
                Spacer()
            }
        }
    }

    private func stampLabel(_ text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 44, weight: .black, design: .rounded))
            .foregroundStyle(color.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.8), lineWidth: 5)
            )
            .rotationEffect(.degrees(rotation))
    }

    private func swipeOverlay(_ result: SwipeResult) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: result == .accepted ? "hands.clap.fill" : "cloud.rain.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(result == .accepted ? LapseTheme.accent : LapseTheme.textSecondary)
                    .symbolEffect(.bounce, value: swipeResult != nil)

                Text(result == .accepted
                     ? "I'll take that as a pass"
                     : "Wait — come back!")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(LapseTheme.textPrimary)

                Text(result == .accepted
                     ? "So... when do I start?"
                     : "I built this entire app from scratch in SwiftUI.\nJust saying.")
                    .font(.system(size: 15))
                    .foregroundStyle(LapseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    swipeResult = nil
                }
            } label: {
                Text(result == .accepted
                     ? "Okay but seriously, tap my card"
                     : "Fine, one more look")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(LapseTheme.accent)
                    .cornerRadius(24)
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        appState.togglePortfolioInterest()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: appState.portfolioInterested ? "heart.fill" : "heart")
                                .foregroundStyle(appState.portfolioInterested ? LapseTheme.accent : LapseTheme.textSecondary)
                            Text("\(appState.portfolioInterestCount)")
                                .font(LapseTheme.captionFont)
                                .foregroundStyle(LapseTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.portfolioInterested)

                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .foregroundStyle(LapseTheme.textSecondary)
                        Text("\(appState.portfolioViewCount)")
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
            .contentShape(Rectangle())
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
