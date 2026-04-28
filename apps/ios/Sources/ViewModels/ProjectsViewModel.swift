import Foundation

@MainActor @Observable
final class ProjectsViewModel {
    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?

    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            projects = try await apiClient.listProjects(portfolioId: 1)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
