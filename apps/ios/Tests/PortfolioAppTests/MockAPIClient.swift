import Foundation
@testable import PortfolioApp

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    let baseURL: URL = URL(string: "http://mock")!

    var portfolioResult: Result<PortfolioResponse, Error> = .failure(MockError.notConfigured)
    var projectResult: Result<Project, Error> = .failure(MockError.notConfigured)
    var interestedResult: Result<InterestedResponse, Error> = .failure(MockError.notConfigured)

    enum MockError: Error { case notConfigured }

    func getPortfolio(id: Int) async throws -> PortfolioResponse { try portfolioResult.get() }
    func postPortfolioView(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func postPortfolioInterested(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func listProjects(portfolioId: Int) async throws -> [Project] { [] }
    func getProject(id: Int) async throws -> Project { try projectResult.get() }
    func postProjectView(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func postInterested(projectId: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func listQA(portfolioId: Int) async throws -> [QAPair] { [] }
    func ask(portfolioId: Int, query: String) async throws -> AskResponse { .init(match: nil, fallback: nil) }
    func postAMAQuestion(portfolioId: Int, question: String) async throws -> AMAResponse { .init(conversationId: 0, messageId: 0) }
    func createNote(portfolioId: Int, name: String, message: String) async throws -> CreateNoteResponse { .init(id: 0) }
    func listConversations(portfolioId: Int) async throws -> ConversationsResponse { .init(conversations: [], theatre: true) }
    func getMessages(conversationId: Int) async throws -> MessagesResponse { .init(messages: [], theatre: true) }
    func sendMessage(conversationId: Int, sender: String, body: String) async throws -> SendMessageResponse { .init(id: 0) }
}
