import SwiftUI

struct LeaveNoteView: View {
    @State private var viewModel: LeaveNoteViewModel

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: LeaveNoteViewModel(apiClient: apiClient))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LapseTheme.cardPadding) {
                if viewModel.isSent {
                    sentConfirmation
                } else {
                    noteForm
                }
            }
            .padding(.top, LapseTheme.sectionSpacing)
        }
        .background(LapseTheme.background)
        .grainOverlay()
        .navigationTitle("Leave a Note")
    }

    private var noteForm: some View {
        VStack(spacing: 12) {
            TextField("Name", text: $viewModel.name)
                .textFieldStyle(.plain)
                .font(LapseTheme.bodyFont)
                .padding(12)
                .background(LapseTheme.surface)
                .cornerRadius(LapseTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                        .stroke(LapseTheme.border, lineWidth: 1)
                )

            TextEditor(text: $viewModel.message)
                .font(LapseTheme.bodyFont)
                .frame(minHeight: 120)
                .padding(8)
                .background(LapseTheme.surface)
                .cornerRadius(LapseTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                        .stroke(LapseTheme.border, lineWidth: 1)
                )

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(LapseTheme.captionFont)
                    .foregroundStyle(LapseTheme.accent)
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
                        .font(LapseTheme.headlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(viewModel.isValid ? LapseTheme.accent : LapseTheme.border)
            .foregroundStyle(.white)
            .cornerRadius(LapseTheme.cornerRadius)
            .disabled(!viewModel.isValid || viewModel.isSubmitting)
        }
        .padding(.horizontal, LapseTheme.cardPadding)
    }

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(LapseTheme.accent)

            Text("Your note has been sent")
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textPrimary)

            Text("Thanks for reaching out!")
                .font(LapseTheme.bodyFont)
                .foregroundStyle(LapseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .polaroidCard(index: 30)
        .padding(.horizontal, LapseTheme.cardPadding)
    }
}
