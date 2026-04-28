import Foundation

@MainActor @Observable
final class AskViewModel {
    var cannedPrompts: [QAPair] = []
    var answerText: String?
    var showFallback = false
    var query = ""
    var isLoading = false
    var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadPrompts() async {
        do {
            cannedPrompts = try await apiClient.listQA(portfolioId: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ask(_ question: String) async {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        answerText = nil
        showFallback = false

        do {
            let response = try await apiClient.ask(portfolioId: 1, query: question)
            if let match = response.match {
                answerText = match.answer
            } else {
                showFallback = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
