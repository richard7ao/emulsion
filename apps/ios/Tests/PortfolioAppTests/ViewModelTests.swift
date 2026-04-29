import XCTest
@testable import PortfolioApp

@MainActor
final class ViewModelTests: XCTestCase {

    func testPortfolioViewModelInitialState() {
        let vm = PortfolioViewModel(apiClient: MockAPIClient())
        XCTAssertNil(vm.portfolio)
        XCTAssertTrue(vm.experiences.isEmpty)
        XCTAssertTrue(vm.skills.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testPortfolioViewModelLoadHappyPath() async {
        let mock = MockAPIClient()
        mock.portfolioResult = .success(PortfolioResponse(
            portfolio: Portfolio(
                id: 1, name: "Richard", bio: "B", photoPath: nil,
                summary: "S", createdAt: "", viewCount: 0, interestedCount: 0
            ),
            experiences: [],
            skills: []
        ))
        let vm = PortfolioViewModel(apiClient: mock)

        await vm.load()

        XCTAssertEqual(vm.portfolio?.name, "Richard")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testPortfolioViewModelLoadErrorPath() async {
        let mock = MockAPIClient()
        mock.portfolioResult = .failure(APIError.httpError(statusCode: 500))
        let vm = PortfolioViewModel(apiClient: mock)

        await vm.load()

        XCTAssertNil(vm.portfolio)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testProjectDetailMarkInterestedIncrementsLocalCount() async {
        let mock = MockAPIClient()
        mock.projectResult = .success(Project(
            id: 1, portfolioId: 1, title: "P", role: "R",
            writeup: "W", screenshots: "[]",
            viewCount: 0, interestedCount: 4
        ))
        let appState = AppState(apiClient: mock)
        let vm = ProjectDetailViewModel(apiClient: mock, projectId: 1, appState: appState)

        await vm.load()
        await vm.markInterested()

        XCTAssertEqual(vm.project?.interestedCount, 5)
        XCTAssertTrue(vm.hasMarkedInterested)
        XCTAssertTrue(appState.isProjectInterested(1))
    }
}
