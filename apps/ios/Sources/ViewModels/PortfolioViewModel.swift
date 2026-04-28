import Foundation

@MainActor @Observable
final class PortfolioViewModel {
    var portfolio: Portfolio?
    var experiences: [Experience] = []
    var skills: [Skill] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.getPortfolio(id: 1)
            portfolio = response.portfolio
            experiences = response.experiences
            skills = response.skills
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
