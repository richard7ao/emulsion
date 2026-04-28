import SwiftUI

struct InboxView: View {
    @State private var viewModel: InboxViewModel

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: InboxViewModel(apiClient: apiClient))
    }

    private var amaConversation: Conversation? {
        viewModel.conversations.first { $0.participantName == amaParticipantName }
    }

    private var regularConversations: [Conversation] {
        viewModel.conversations.filter { $0.participantName != "Ask Me Anything" }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else {
                    if let ama = amaConversation {
                        NavigationLink {
                            ConversationThreadView(viewModel: viewModel, conversation: ama)
                        } label: {
                            amaRow(ama)
                        }

                        Rectangle()
                            .fill(LapseTheme.background)
                            .frame(height: 12)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(regularConversations) { convo in
                            NavigationLink {
                                ConversationThreadView(viewModel: viewModel, conversation: convo)
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

    private func amaRow(_ convo: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(LapseTheme.accent)
                Text(convo.participantName)
                    .font(LapseTheme.headlineFont)
                    .foregroundStyle(LapseTheme.textPrimary)
                Spacer()
                Text(formatTimestamp(convo.updatedAt))
                    .font(LapseTheme.captionFont)
                    .foregroundStyle(LapseTheme.textSecondary)
            }
            Text(convo.lastMessage)
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(LapseTheme.cardPadding)
        .background(LapseTheme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                .stroke(LapseTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(LapseTheme.cornerRadius)
        .padding(.horizontal, LapseTheme.cardPadding)
        .padding(.top, LapseTheme.cardPadding)
    }

    private func conversationRow(_ convo: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(convo.participantName)
                    .font(LapseTheme.headlineFont)
                    .foregroundStyle(LapseTheme.textPrimary)
                Spacer()
                Text(formatTimestamp(convo.updatedAt))
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
