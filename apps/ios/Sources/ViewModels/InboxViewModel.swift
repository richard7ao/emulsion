import Foundation

@MainActor @Observable
final class InboxViewModel {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var isTheatre = false
    var isLoading = false
    var errorMessage: String?

    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.listConversations(portfolioId: 1)
            conversations = response.conversations
            isTheatre = response.theatre
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMessages(conversationId: Int) async {
        isLoading = true

        do {
            let response = try await apiClient.getMessages(conversationId: conversationId)
            messages = response.messages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
