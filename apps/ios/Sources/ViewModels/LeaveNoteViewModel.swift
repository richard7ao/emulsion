import Foundation

@MainActor @Observable
final class LeaveNoteViewModel {
    var name = ""
    var message = ""
    var isSubmitting = false
    var isSent = false
    var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func submit() async {
        guard isValid else {
            errorMessage = "Name and message are required"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await apiClient.createNote(
                portfolioId: 1,
                name: name.trimmingCharacters(in: .whitespaces),
                message: message.trimmingCharacters(in: .whitespaces)
            )
            isSent = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
