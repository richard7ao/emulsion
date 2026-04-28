import SwiftUI

struct AskView: View {
    @State private var viewModel: AskViewModel

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: AskViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LapseTheme.cardPadding) {
                SectionHeaderView(title: "FAQs")

                ForEach(viewModel.cannedPrompts) { prompt in
                    faqCard(prompt)
                        .padding(.horizontal, LapseTheme.cardPadding)
                }

                Divider()
                    .padding(.horizontal, LapseTheme.cardPadding)
                    .padding(.vertical, 4)

                SectionHeaderView(title: "Ask Me Anything")

                HStack {
                    TextField("Ask a question...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .font(LapseTheme.bodyFont)
                        .onSubmit { Task { await viewModel.submitQuestion() } }

                    Button {
                        Task { await viewModel.submitQuestion() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? LapseTheme.border : LapseTheme.accent
                            )
                    }
                    .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(LapseTheme.cardPadding)
                .background(LapseTheme.surface)
                .cornerRadius(LapseTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                        .stroke(LapseTheme.border, lineWidth: 1)
                )
                .padding(.horizontal, LapseTheme.cardPadding)

                if viewModel.isLoading {
                    ProgressView()
                }

                if viewModel.questionSent {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LapseTheme.accent)
                        Text("Question sent — check the Inbox")
                            .font(LapseTheme.bodyFont)
                            .foregroundStyle(LapseTheme.textSecondary)
                    }
                    .padding(LapseTheme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LapseTheme.accent.opacity(0.08))
                    .cornerRadius(LapseTheme.cornerRadius)
                    .padding(.horizontal, LapseTheme.cardPadding)
                }
            }
            .padding(.bottom, LapseTheme.sectionSpacing)
        }
        .background(LapseTheme.background)
        .grainOverlay()
        .navigationTitle("Ask Richard")
        .task {
            await viewModel.loadPrompts()
        }
    }

    private func faqCard(_ prompt: QAPair) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleExpanded(prompt.id)
                }
            } label: {
                HStack {
                    Text(prompt.prompt)
                        .font(LapseTheme.bodyFont)
                        .foregroundStyle(LapseTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: viewModel.isExpanded(prompt.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(LapseTheme.textSecondary)
                }
                .padding(LapseTheme.cardPadding)
            }

            if viewModel.isExpanded(prompt.id) {
                Divider()
                    .padding(.horizontal, LapseTheme.cardPadding)
                Text(prompt.answer)
                    .font(LapseTheme.bodyFont)
                    .foregroundStyle(LapseTheme.textSecondary)
                    .padding(LapseTheme.cardPadding)
            }
        }
        .background(LapseTheme.surface)
        .cornerRadius(LapseTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                .stroke(LapseTheme.border, lineWidth: 1)
        )
    }
}
