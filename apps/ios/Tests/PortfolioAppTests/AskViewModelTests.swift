import XCTest
@testable import PortfolioApp

@MainActor
final class AskViewModelTests: XCTestCase {

    func testLoadPromptsHappyPath() async {
        let mock = MockAPIClient()
        mock.qaListResult = .success([
            QAPair(id: 1, portfolioId: 1, prompt: "What do you do?", answer: "Build things", isCanned: true)
        ])
        let vm = AskViewModel(apiClient: mock)

        await vm.loadPrompts()

        XCTAssertEqual(vm.cannedPrompts.count, 1)
        XCTAssertEqual(vm.cannedPrompts.first?.prompt, "What do you do?")
        XCTAssertNil(vm.errorMessage)
    }

    func testLoadPromptsErrorPath() async {
        let mock = MockAPIClient()
        mock.qaListResult = .failure(APIError.httpError(statusCode: 500))
        let vm = AskViewModel(apiClient: mock)

        await vm.loadPrompts()

        XCTAssertTrue(vm.cannedPrompts.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSubmitQuestionHappyPath() async {
        let mock = MockAPIClient()
        mock.amaResult = .success(AMAResponse(conversationId: 1, messageId: 42))
        let vm = AskViewModel(apiClient: mock)
        vm.query = "How do you handle scaling?"

        await vm.submitQuestion()

        XCTAssertTrue(vm.questionSent)
        XCTAssertTrue(vm.query.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testSubmitQuestionEmptyQueryDoesNothing() async {
        let mock = MockAPIClient()
        mock.amaResult = .failure(APIError.httpError(statusCode: 500))
        let vm = AskViewModel(apiClient: mock)
        vm.query = "   "

        await vm.submitQuestion()

        XCTAssertFalse(vm.questionSent)
        XCTAssertNil(vm.errorMessage)
    }

    func testSubmitQuestionErrorPath() async {
        let mock = MockAPIClient()
        mock.amaResult = .failure(APIError.httpError(statusCode: 500))
        let vm = AskViewModel(apiClient: mock)
        vm.query = "Tell me about your work"

        await vm.submitQuestion()

        XCTAssertFalse(vm.questionSent)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testToggleExpanded() {
        let vm = AskViewModel(apiClient: MockAPIClient())

        XCTAssertFalse(vm.isExpanded(1))
        vm.toggleExpanded(1)
        XCTAssertTrue(vm.isExpanded(1))
        vm.toggleExpanded(1)
        XCTAssertFalse(vm.isExpanded(1))
    }
}
