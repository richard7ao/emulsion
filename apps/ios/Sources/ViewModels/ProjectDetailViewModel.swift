import Foundation

@MainActor @Observable
final class ProjectDetailViewModel {
    var project: Project?
    var isLoading = false
    var errorMessage: String?
    var hasMarkedInterested = false

    private let apiClient: any APIClientProtocol
    private let projectId: Int
    private weak var appState: AppState?

    init(apiClient: any APIClientProtocol, projectId: Int, appState: AppState? = nil) {
        self.apiClient = apiClient
        self.projectId = projectId
        self.appState = appState
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            project = try await apiClient.getProject(id: projectId)
            hasMarkedInterested = appState?.isProjectInterested(projectId) ?? false
            Task { _ = try? await apiClient.postProjectView(id: projectId) }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func markInterested() async {
        guard !hasMarkedInterested, var current = project else { return }

        current.interestedCount += 1
        project = current
        hasMarkedInterested = true
        appState?.markProjectInterested(projectId)

        do {
            _ = try await apiClient.postInterested(projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
