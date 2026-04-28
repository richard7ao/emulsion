import SwiftUI

struct GrainOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(
            Canvas { context, size in
                for _ in 0..<300 {
                    let x = Double.random(in: 0..<size.width)
                    let y = Double.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.02...0.06)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                        with: .color(.black.opacity(opacity))
                    )
                }
            }
            .allowsHitTesting(false)
        )
    }
}

extension View {
    func grainOverlay() -> some View {
        modifier(GrainOverlay())
    }
}
