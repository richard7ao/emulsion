import SwiftUI

struct PolaroidCard: ViewModifier {
    let index: Int

    // Seeded rotation based on index — never random
    private var rotation: Double {
        let seed = Double(index)
        return sin(seed * 1.7) * 3.0
    }

    func body(content: Content) -> some View {
        content
            .padding(LapseTheme.cardPadding)
            .background(LapseTheme.surface)
            .cornerRadius(LapseTheme.cornerRadius)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    func polaroidCard(index: Int) -> some View {
        modifier(PolaroidCard(index: index))
    }
}
