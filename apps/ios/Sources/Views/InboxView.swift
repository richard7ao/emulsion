import SwiftUI

struct InboxView: View {
    @State private var viewModel: InboxViewModel

    init(apiClient: any APIClientProtocol) {
        _viewModel = State(initialValue: InboxViewModel(apiClient: apiClient))
    }

    private var amaConversation: Conversation? {
        viewModel.conversations.first { $0.participantName == amaParticipantName }
    }

    private var regularConversations: [Conversation] {
        viewModel.conversations.filter { $0.participantName != amaParticipantName }
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
                            .fill(EmulsionTheme.background)
                            .frame(height: 12)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(regularConversations) { convo in
                            HStack(spacing: 0) {
                                NavigationLink {
                                    ConversationThreadView(viewModel: viewModel, conversation: convo)
                                } label: {
                                    conversationRow(convo)
                                }

                                Button {
                                    Task { await viewModel.deleteConversation(id: convo.id) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.body)
                                        .foregroundStyle(EmulsionTheme.textSecondary)
                                        .frame(width: 44, height: 44)
                                }
                                .padding(.trailing, 8)
                            }
                            .background(EmulsionTheme.surface)
                            .overlay(alignment: .bottom) {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .background(EmulsionTheme.background)
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
                    .foregroundStyle(EmulsionTheme.accent)
                Text(convo.participantName)
                    .font(EmulsionTheme.headlineFont)
                    .foregroundStyle(EmulsionTheme.textPrimary)
                Spacer()
                Text(formatTimestamp(convo.updatedAt))
                    .font(EmulsionTheme.captionFont)
                    .foregroundStyle(EmulsionTheme.textSecondary)
            }
            Text(convo.lastMessage)
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(EmulsionTheme.cardPadding)
        .background(EmulsionTheme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: EmulsionTheme.cornerRadius)
                .stroke(EmulsionTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(EmulsionTheme.cornerRadius)
        .padding(.horizontal, EmulsionTheme.cardPadding)
        .padding(.top, EmulsionTheme.cardPadding)
    }

    private func conversationRow(_ convo: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(convo.participantName)
                    .font(EmulsionTheme.headlineFont)
                    .foregroundStyle(EmulsionTheme.textPrimary)
                Spacer()
                Text(formatTimestamp(convo.updatedAt))
                    .font(EmulsionTheme.captionFont)
                    .foregroundStyle(EmulsionTheme.textSecondary)
            }
            Text(convo.lastMessage)
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(EmulsionTheme.cardPadding)
    }
}
