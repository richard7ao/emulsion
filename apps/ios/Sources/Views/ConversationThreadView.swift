import SwiftUI

struct ConversationThreadView: View {
    @Bindable var viewModel: InboxViewModel
    let conversation: Conversation
    @State private var draftText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        messageBubble(msg)
                    }
                }
                .padding(EmulsionTheme.cardPadding)
            }

            Divider()

            HStack {
                TextField("Message...", text: $draftText)
                    .textFieldStyle(.plain)
                    .font(EmulsionTheme.bodyFont)
                    .onSubmit { send() }

                Button { send() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(draftText.trimmingCharacters(in: .whitespaces).isEmpty ? EmulsionTheme.border : EmulsionTheme.accent)
                }
                .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(EmulsionTheme.surface)
        }
        .background(EmulsionTheme.background)
        .navigationTitle(conversation.participantName)
        .task {
            await viewModel.loadMessages(conversationId: conversation.id)
        }
    }

    private func send() {
        let text = draftText
        draftText = ""
        Task {
            await viewModel.sendMessage(conversationId: conversation.id, body: text)
        }
    }

    private func messageBubble(_ msg: Message) -> some View {
        let isMe = msg.sender == "Richard"
        return HStack {
            if isMe { Spacer() }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Text(msg.body)
                    .font(EmulsionTheme.bodyFont)
                    .foregroundStyle(EmulsionTheme.textPrimary)
                Text(formatTimestamp(msg.createdAt))
                    .font(EmulsionTheme.captionFont)
                    .foregroundStyle(EmulsionTheme.textSecondary)
            }
            .padding(12)
            .background(isMe ? EmulsionTheme.accent.opacity(0.1) : EmulsionTheme.surface)
            .cornerRadius(EmulsionTheme.cornerRadius)
            if !isMe { Spacer() }
        }
    }
}
