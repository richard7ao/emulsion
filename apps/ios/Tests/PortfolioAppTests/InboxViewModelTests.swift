import XCTest
@testable import PortfolioApp

@MainActor
final class InboxViewModelTests: XCTestCase {

    func testLoadConversationsHappyPath() async {
        let mock = MockAPIClient()
        mock.conversationsResult = .success(ConversationsResponse(
            conversations: [
                Conversation(id: 1, portfolioId: 1, participantName: "Alice", lastMessage: "Hey", updatedAt: "2026-04-29 10:00:00", isTheatre: false)
            ],
            theatre: false
        ))
        let vm = InboxViewModel(apiClient: mock)

        await vm.loadConversations()

        XCTAssertEqual(vm.conversations.count, 1)
        XCTAssertEqual(vm.conversations.first?.participantName, "Alice")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoadConversationsErrorPath() async {
        let mock = MockAPIClient()
        mock.conversationsResult = .failure(APIError.httpError(statusCode: 500))
        let vm = InboxViewModel(apiClient: mock)

        await vm.loadConversations()

        XCTAssertTrue(vm.conversations.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadMessagesHappyPath() async {
        let mock = MockAPIClient()
        mock.messagesResult = .success(MessagesResponse(
            messages: [
                Message(id: 1, conversationId: 1, sender: "Alice", body: "Hello", createdAt: "2026-04-29 10:00:00"),
                Message(id: 2, conversationId: 1, sender: "Richard", body: "Hi there", createdAt: "2026-04-29 10:01:00"),
            ],
            theatre: false
        ))
        let vm = InboxViewModel(apiClient: mock)

        await vm.loadMessages(conversationId: 1)

        XCTAssertEqual(vm.messages.count, 2)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoadMessagesErrorPath() async {
        let mock = MockAPIClient()
        mock.messagesResult = .failure(APIError.httpError(statusCode: 404))
        let vm = InboxViewModel(apiClient: mock)

        await vm.loadMessages(conversationId: 999)

        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testSendMessageHappyPath() async {
        let mock = MockAPIClient()
        mock.sendMessageResult = .success(SendMessageResponse(id: 5))
        mock.messagesResult = .success(MessagesResponse(
            messages: [
                Message(id: 5, conversationId: 1, sender: "Richard", body: "New message", createdAt: "2026-04-29 12:00:00")
            ],
            theatre: false
        ))
        let vm = InboxViewModel(apiClient: mock)

        await vm.sendMessage(conversationId: 1, body: "New message")

        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertNil(vm.errorMessage)
    }

    func testSendMessageEmptyBodyDoesNothing() async {
        let mock = MockAPIClient()
        mock.sendMessageResult = .failure(APIError.httpError(statusCode: 400))
        let vm = InboxViewModel(apiClient: mock)

        await vm.sendMessage(conversationId: 1, body: "   ")

        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }

    func testSendMessageErrorPath() async {
        let mock = MockAPIClient()
        mock.sendMessageResult = .failure(APIError.httpError(statusCode: 500))
        let vm = InboxViewModel(apiClient: mock)

        await vm.sendMessage(conversationId: 1, body: "hello")

        XCTAssertNotNil(vm.errorMessage)
    }
}
