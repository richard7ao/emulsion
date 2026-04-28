import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}
