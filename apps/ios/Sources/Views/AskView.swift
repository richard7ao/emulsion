import SwiftUI

struct AskView: View {
    @State private var viewModel: AskViewModel

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: AskViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LapseTheme.cardPadding) {
                SectionHeaderView(title: "Ask Me Anything")

                ForEach(viewModel.cannedPrompts) { prompt in
                    Button {
                        Task { await viewModel.ask(prompt.prompt) }
                    } label: {
                        Text(prompt.prompt)
                            .font(LapseTheme.bodyFont)
                            .foregroundStyle(LapseTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(LapseTheme.cardPadding)
                            .background(LapseTheme.surface)
                            .cornerRadius(LapseTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                                    .stroke(LapseTheme.border, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, LapseTheme.cardPadding)
                }

                HStack {
                    TextField("Ask a question...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .font(LapseTheme.bodyFont)

                    Button {
                        Task { await viewModel.ask(viewModel.query) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(LapseTheme.accent)
                    }
                    .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(LapseTheme.cardPadding)
                .background(LapseTheme.surface)
                .cornerRadius(LapseTheme.cornerRadius)
                .padding(.horizontal, LapseTheme.cardPadding)

                if viewModel.isLoading {
                    ProgressView()
                }

                if let answer = viewModel.answerText {
                    Text(answer)
                        .font(LapseTheme.bodyFont)
                        .foregroundStyle(LapseTheme.textPrimary)
                        .padding(LapseTheme.cardPadding)
                        .polaroidCard(index: 20)
                        .padding(.horizontal, LapseTheme.cardPadding)
                }

                if viewModel.showFallback {
                    VStack(spacing: 12) {
                        Text("I'd love to chat — leave a note below")
                            .font(LapseTheme.bodyFont)
                            .foregroundStyle(LapseTheme.textSecondary)
                    }
                    .padding(LapseTheme.cardPadding)
                    .polaroidCard(index: 21)
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
}
