import Foundation

@MainActor @Observable
final class AskViewModel {
    var cannedPrompts: [QAPair] = []
    var expandedPromptIds: Set<Int> = []
    var query = ""
    var isLoading = false
    var questionSent = false
    var errorMessage: String?

    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func loadPrompts() async {
        do {
            cannedPrompts = try await apiClient.listQA(portfolioId: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleExpanded(_ id: Int) {
        if expandedPromptIds.contains(id) {
            expandedPromptIds.remove(id)
        } else {
            expandedPromptIds.insert(id)
        }
    }

    func isExpanded(_ id: Int) -> Bool {
        expandedPromptIds.contains(id)
    }

    func submitQuestion() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isLoading = true
        questionSent = false

        do {
            _ = try await apiClient.postAMAQuestion(portfolioId: 1, question: q)
            questionSent = true
            query = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
