import XCTest
@testable import PortfolioApp

final class ModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func testPortfolioDecoding() throws {
        let json = """
        {"id":1,"name":"Richard","bio":"Engineer","photo_path":null,
         "summary":"Summary","created_at":"2026-01-01","view_count":10,"interested_count":5}
        """.data(using: .utf8)!
        let p = try decoder.decode(Portfolio.self, from: json)
        XCTAssertEqual(p.id, 1)
        XCTAssertEqual(p.name, "Richard")
        XCTAssertNil(p.photoPath)
        XCTAssertEqual(p.viewCount, 10)
    }

    func testExperienceDecoding() throws {
        let json = """
        {"id":1,"portfolio_id":1,"company":"Acme","role":"Engineer",
         "dates":"2024-2026","bullets":"[\\"Built X\\",\\"Led Y\\"]"}
        """.data(using: .utf8)!
        let e = try decoder.decode(Experience.self, from: json)
        XCTAssertEqual(e.company, "Acme")
        XCTAssertEqual(e.bullets, "[\"Built X\",\"Led Y\"]")
    }

    func testProjectDecoding() throws {
        let json = """
        {"id":1,"portfolio_id":1,"title":"App","role":"Lead",
         "writeup":"Details","screenshots":"[]","view_count":0,"interested_count":0}
        """.data(using: .utf8)!
        let p = try decoder.decode(Project.self, from: json)
        XCTAssertEqual(p.title, "App")
    }

    func testPortfolioResponseDecoding() throws {
        let json = """
        {"portfolio":{"id":1,"name":"R","bio":"B","photo_path":null,
         "summary":"S","created_at":"","view_count":0,"interested_count":0},
         "experiences":[],"skills":[]}
        """.data(using: .utf8)!
        let resp = try decoder.decode(PortfolioResponse.self, from: json)
        XCTAssertEqual(resp.portfolio.name, "R")
        XCTAssertTrue(resp.experiences.isEmpty)
    }

    func testAskResponseWithMatch() throws {
        let json = """
        {"match":{"prompt":"test","answer":"yes"},"fallback":null}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AskResponse.self, from: json)
        XCTAssertEqual(resp.match?.prompt, "test")
        XCTAssertNil(resp.fallback)
    }

    func testAskResponseWithFallback() throws {
        let json = """
        {"match":null,"fallback":"leave_a_note"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AskResponse.self, from: json)
        XCTAssertNil(resp.match)
        XCTAssertEqual(resp.fallback, "leave_a_note")
    }

    func testParseJSONArrayValid() {
        let result = parseJSONArray("[\"a\",\"b\",\"c\"]")
        XCTAssertEqual(result, ["a", "b", "c"])
    }

    func testParseJSONArrayEmpty() {
        let result = parseJSONArray("")
        XCTAssertTrue(result.isEmpty)
    }

    func testParseJSONArrayInvalidFallback() {
        let result = parseJSONArray("not json")
        XCTAssertEqual(result, ["not json"])
    }

    func testFormatTimestampValid() {
        let result = formatTimestamp("2026-04-28 14:30:00")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("Apr") || result.contains("28"))
    }

    func testFormatTimestampInvalidPassthrough() {
        let result = formatTimestamp("invalid")
        XCTAssertEqual(result, "invalid")
    }

    func testConversationsResponseDecoding() throws {
        let json = """
        {"conversations":[],"theatre":true}
        """.data(using: .utf8)!
        let resp = try decoder.decode(ConversationsResponse.self, from: json)
        XCTAssertTrue(resp.theatre)
        XCTAssertTrue(resp.conversations.isEmpty)
    }
}
