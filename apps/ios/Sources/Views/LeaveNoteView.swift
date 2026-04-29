import SwiftUI

struct LeaveNoteView: View {
    @State private var viewModel: LeaveNoteViewModel

    init(apiClient: any APIClientProtocol) {
        _viewModel = State(initialValue: LeaveNoteViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: EmulsionTheme.cardPadding) {
                if viewModel.isSent {
                    sentConfirmation
                } else {
                    noteForm
                }
            }
            .padding(.top, EmulsionTheme.sectionSpacing)
        }
        .background(EmulsionTheme.background)
        .grainOverlay()
        .navigationTitle("Leave a Note")
    }

    private var noteForm: some View {
        VStack(spacing: 12) {
            TextField("Name", text: $viewModel.name)
                .textFieldStyle(.plain)
                .font(EmulsionTheme.bodyFont)
                .padding(12)
                .borderedCard()

            TextEditor(text: $viewModel.message)
                .font(EmulsionTheme.bodyFont)
                .frame(minHeight: 120)
                .padding(8)
                .borderedCard()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(EmulsionTheme.captionFont)
                    .foregroundStyle(EmulsionTheme.accent)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Send Note")
                        .font(EmulsionTheme.headlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(viewModel.isValid ? EmulsionTheme.accent : EmulsionTheme.border)
            .foregroundStyle(.white)
            .cornerRadius(EmulsionTheme.cornerRadius)
            .disabled(!viewModel.isValid || viewModel.isSubmitting)
        }
        .padding(.horizontal, EmulsionTheme.cardPadding)
    }

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(EmulsionTheme.accent)

            Text("Your note has been sent")
                .font(EmulsionTheme.headlineFont)
                .foregroundStyle(EmulsionTheme.textPrimary)

            Text("Thanks for reaching out!")
                .font(EmulsionTheme.bodyFont)
                .foregroundStyle(EmulsionTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .polaroidCard(index: 30)
        .padding(.horizontal, EmulsionTheme.cardPadding)
    }
}
