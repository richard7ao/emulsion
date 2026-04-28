import XCTest
@testable import PortfolioApp

final class APIClientTests: XCTestCase {

    func testBaseURLDefault() {
        let client = APIClient()
        XCTAssertEqual(client.baseURL.absoluteString, "http://localhost:8080")
    }

    func testBaseURLCustom() {
        let client = APIClient(baseURL: URL(string: "http://example.com:3000")!)
        XCTAssertEqual(client.baseURL.absoluteString, "http://example.com:3000")
    }
}
