import XCTest
@testable import PortfolioApp

@MainActor
final class ViewModelTests: XCTestCase {

    func testPortfolioViewModelInitialState() {
        let vm = PortfolioViewModel(apiClient: APIClient())
        XCTAssertNil(vm.portfolio)
        XCTAssertTrue(vm.experiences.isEmpty)
        XCTAssertTrue(vm.skills.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }
}
