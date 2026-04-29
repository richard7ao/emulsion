import XCTest
@testable import PortfolioApp

@MainActor
final class LeaveNoteViewModelTests: XCTestCase {

    func testIsValidBothFieldsFilled() {
        let vm = LeaveNoteViewModel(apiClient: MockAPIClient())
        vm.name = "Alice"
        vm.message = "Great work"
        XCTAssertTrue(vm.isValid)
    }

    func testIsValidEmptyName() {
        let vm = LeaveNoteViewModel(apiClient: MockAPIClient())
        vm.name = "   "
        vm.message = "Great work"
        XCTAssertFalse(vm.isValid)
    }

    func testIsValidEmptyMessage() {
        let vm = LeaveNoteViewModel(apiClient: MockAPIClient())
        vm.name = "Alice"
        vm.message = ""
        XCTAssertFalse(vm.isValid)
    }

    func testSubmitHappyPath() async {
        let mock = MockAPIClient()
        mock.createNoteResult = .success(CreateNoteResponse(id: 7))
        let vm = LeaveNoteViewModel(apiClient: mock)
        vm.name = "Alice"
        vm.message = "Great portfolio"

        await vm.submit()

        XCTAssertTrue(vm.isSent)
        XCTAssertFalse(vm.isSubmitting)
        XCTAssertNil(vm.errorMessage)
    }

    func testSubmitInvalidFieldsSetsError() async {
        let vm = LeaveNoteViewModel(apiClient: MockAPIClient())
        vm.name = ""
        vm.message = "hello"

        await vm.submit()

        XCTAssertFalse(vm.isSent)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSubmitNetworkErrorPath() async {
        let mock = MockAPIClient()
        mock.createNoteResult = .failure(APIError.httpError(statusCode: 500))
        let vm = LeaveNoteViewModel(apiClient: mock)
        vm.name = "Alice"
        vm.message = "Great portfolio"

        await vm.submit()

        XCTAssertFalse(vm.isSent)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isSubmitting)
    }
}
