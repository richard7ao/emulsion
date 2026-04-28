import SwiftUI

@MainActor @Observable
final class AppState {
    var selectedTab: Int = 0
    var interestedProjectIds: Set<Int> = []
    var portfolioInterested: Bool = false
    var portfolioInterestCount: Int = 0
    var portfolioViewCount: Int = 0
    let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func togglePortfolioInterest() {
        guard !portfolioInterested else { return }
        portfolioInterested = true
        portfolioInterestCount += 1
        Task {
            _ = try? await apiClient.postPortfolioInterested(id: 1)
        }
    }

    func markProjectInterested(_ id: Int) {
        interestedProjectIds.insert(id)
    }

    func isProjectInterested(_ id: Int) -> Bool {
        interestedProjectIds.contains(id)
    }
}
