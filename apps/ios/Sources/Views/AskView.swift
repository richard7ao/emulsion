import SwiftUI

struct AskView: View {
    @State private var viewModel: AskViewModel

    init(apiClient: any APIClientProtocol) {
        _viewModel = State(initialValue: AskViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: EmulsionTheme.cardPadding) {
                SectionHeaderView(title: "FAQs")

                ForEach(viewModel.cannedPrompts) { prompt in
                    faqCard(prompt)
                        .padding(.horizontal, EmulsionTheme.cardPadding)
                }

                Divider()
                    .padding(.horizontal, EmulsionTheme.cardPadding)
                    .padding(.vertical, 4)

                SectionHeaderView(title: "Ask Me Anything")

                HStack {
                    TextField("Ask a question...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .font(EmulsionTheme.bodyFont)
                        .onSubmit { Task { await viewModel.submitQuestion() } }

                    Button {
                        Task { await viewModel.submitQuestion() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? EmulsionTheme.border : EmulsionTheme.accent
                            )
                    }
                    .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(EmulsionTheme.cardPadding)
                .borderedCard()
                .padding(.horizontal, EmulsionTheme.cardPadding)

                if viewModel.isLoading {
                    ProgressView()
                }

                if viewModel.questionSent {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(EmulsionTheme.accent)
                        Text("Question sent — check the Inbox")
                            .font(EmulsionTheme.bodyFont)
                            .foregroundStyle(EmulsionTheme.textSecondary)
                    }
                    .padding(EmulsionTheme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(EmulsionTheme.accent.opacity(0.08))
                    .cornerRadius(EmulsionTheme.cornerRadius)
                    .padding(.horizontal, EmulsionTheme.cardPadding)
                }
            }
            .padding(.bottom, EmulsionTheme.sectionSpacing)
        }
        .background(EmulsionTheme.background)
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
                        .font(EmulsionTheme.bodyFont)
                        .foregroundStyle(EmulsionTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: viewModel.isExpanded(prompt.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(EmulsionTheme.textSecondary)
                }
                .padding(EmulsionTheme.cardPadding)
            }

            if viewModel.isExpanded(prompt.id) {
                Divider()
                    .padding(.horizontal, EmulsionTheme.cardPadding)
                Text(prompt.answer)
                    .font(EmulsionTheme.bodyFont)
                    .foregroundStyle(EmulsionTheme.textSecondary)
                    .padding(EmulsionTheme.cardPadding)
            }
        }
        .borderedCard()
    }
}
