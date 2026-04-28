import Foundation

final class APIClient: Sendable {
    let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = URL(string: "http://localhost:8080")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func getPortfolio(id: Int) async throws -> PortfolioResponse {
        try await get("/v1/portfolios/\(id)")
    }

    func postPortfolioView(id: Int) async throws -> InterestedResponse {
        try await post("/v1/portfolios/\(id)/view", body: Optional<String>.none)
    }

    func postPortfolioInterested(id: Int) async throws -> InterestedResponse {
        try await post("/v1/portfolios/\(id)/interested", body: Optional<String>.none)
    }

    func listProjects(portfolioId: Int) async throws -> [Project] {
        try await get("/v1/portfolios/\(portfolioId)/projects")
    }

    func getProject(id: Int) async throws -> Project {
        try await get("/v1/projects/\(id)")
    }

    func postInterested(projectId: Int) async throws -> InterestedResponse {
        try await post("/v1/projects/\(projectId)/interested", body: Optional<String>.none)
    }

    func listQA(portfolioId: Int) async throws -> [QAPair] {
        try await get("/v1/portfolios/\(portfolioId)/qa")
    }

    func ask(portfolioId: Int, query: String) async throws -> AskResponse {
        try await post("/v1/portfolios/\(portfolioId)/qa/ask", body: ["query": query])
    }

    func postAMAQuestion(portfolioId: Int, question: String) async throws -> AMAResponse {
        try await post("/v1/portfolios/\(portfolioId)/ama", body: ["query": question])
    }

    func createNote(portfolioId: Int, name: String, message: String) async throws -> CreateNoteResponse {
        let body = CreateNoteRequest(name: name, message: message)
        return try await post("/v1/portfolios/\(portfolioId)/notes", body: body)
    }

    func listConversations(portfolioId: Int) async throws -> ConversationsResponse {
        try await get("/v1/portfolios/\(portfolioId)/conversations")
    }

    func getMessages(conversationId: Int) async throws -> MessagesResponse {
        try await get("/v1/conversations/\(conversationId)/messages")
    }

    func sendMessage(conversationId: Int, sender: String, body: String) async throws -> SendMessageResponse {
        let req = SendMessageRequest(sender: sender, body: body)
        return try await post("/v1/conversations/\(conversationId)/messages", body: req)
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decode(data)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B?) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decode(data)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
