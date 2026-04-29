import Foundation
@testable import PortfolioApp

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    let baseURL: URL = URL(string: "http://mock")!

    var portfolioResult: Result<PortfolioResponse, Error> = .failure(MockError.notConfigured)
    var projectResult: Result<Project, Error> = .failure(MockError.notConfigured)
    var interestedResult: Result<InterestedResponse, Error> = .failure(MockError.notConfigured)
    var qaListResult: Result<[QAPair], Error> = .success([])
    var askResult: Result<AskResponse, Error> = .success(.init(match: nil, fallback: nil))
    var amaResult: Result<AMAResponse, Error> = .success(.init(conversationId: 1, messageId: 1))
    var createNoteResult: Result<CreateNoteResponse, Error> = .success(.init(id: 1))
    var conversationsResult: Result<ConversationsResponse, Error> = .success(.init(conversations: [], theatre: true))
    var messagesResult: Result<MessagesResponse, Error> = .success(.init(messages: [], theatre: true))
    var sendMessageResult: Result<SendMessageResponse, Error> = .success(.init(id: 1))

    enum MockError: Error { case notConfigured }

    func getPortfolio(id: Int) async throws -> PortfolioResponse { try portfolioResult.get() }
    func postPortfolioView(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func postPortfolioInterested(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func listProjects(portfolioId: Int) async throws -> [Project] { [] }
    func getProject(id: Int) async throws -> Project { try projectResult.get() }
    func postProjectView(id: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func postInterested(projectId: Int) async throws -> InterestedResponse { try interestedResult.get() }
    func listQA(portfolioId: Int) async throws -> [QAPair] { try qaListResult.get() }
    func ask(portfolioId: Int, query: String) async throws -> AskResponse { try askResult.get() }
    func postAMAQuestion(portfolioId: Int, question: String) async throws -> AMAResponse { try amaResult.get() }
    func createNote(portfolioId: Int, name: String, message: String) async throws -> CreateNoteResponse { try createNoteResult.get() }
    func listConversations(portfolioId: Int) async throws -> ConversationsResponse { try conversationsResult.get() }
    func getMessages(conversationId: Int) async throws -> MessagesResponse { try messagesResult.get() }
    func sendMessage(conversationId: Int, sender: String, body: String) async throws -> SendMessageResponse { try sendMessageResult.get() }
}
