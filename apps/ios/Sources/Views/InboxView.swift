import SwiftUI

struct InboxView: View {
    @State private var viewModel: InboxViewModel

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: InboxViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isTheatre {
                    Text("Demo")
                        .font(LapseTheme.captionFont)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LapseTheme.accent)
                        .cornerRadius(LapseTheme.cornerRadius)
                        .padding(.top, 12)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.conversations) { convo in
                            NavigationLink {
                                ConversationThreadView(
                                    viewModel: viewModel,
                                    conversation: convo
                                )
                            } label: {
                                conversationRow(convo)
                            }
                        }
                    }
                }
            }
        }
        .background(LapseTheme.background)
        .grainOverlay()
        .navigationTitle("Inbox")
        .task {
            await viewModel.loadConversations()
        }
    }

    private func conversationRow(_ convo: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(convo.participantName)
                    .font(LapseTheme.headlineFont)
                    .foregroundStyle(LapseTheme.textPrimary)
                Spacer()
                Text(convo.updatedAt)
                    .font(LapseTheme.captionFont)
                    .foregroundStyle(LapseTheme.textSecondary)
            }
            Text(convo.lastMessage)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(LapseTheme.cardPadding)
        .background(LapseTheme.surface)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
