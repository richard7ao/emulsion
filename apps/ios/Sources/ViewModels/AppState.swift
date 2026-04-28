import SwiftUI

@Observable
final class AppState {
    var currentPortfolioIndex: Int = 0
    let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
}
