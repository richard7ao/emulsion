import SwiftUI

enum EmulsionTheme {
    // Warm off-white background
    static let background = Color(red: 250/255, green: 245/255, blue: 235/255)
    static let surface = Color.white
    static let textPrimary = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let textSecondary = Color(red: 120/255, green: 110/255, blue: 100/255)
    static let accent = Color(red: 180/255, green: 80/255, blue: 60/255)
    static let border = Color(red: 220/255, green: 215/255, blue: 205/255)

    // Editorial serif for headings
    static let titleFont = Font.system(.title, design: .serif)
    static let headlineFont = Font.system(.headline, design: .serif)
    static let bodyFont = Font.system(.body, design: .default)
    // Monospace for metadata
    static let captionFont = Font.system(.caption, design: .monospaced)

    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cornerRadius: CGFloat = 4
}

extension View {
    func borderedCard() -> some View {
        self
            .background(EmulsionTheme.surface)
            .cornerRadius(EmulsionTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: EmulsionTheme.cornerRadius)
                    .stroke(EmulsionTheme.border, lineWidth: 1)
            )
    }
}
