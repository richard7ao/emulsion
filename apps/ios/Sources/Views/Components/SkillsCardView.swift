import SwiftUI

struct SkillsCardView: View {
    let skill: Skill
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(skill.category)
                .font(LapseTheme.headlineFont)
                .foregroundStyle(LapseTheme.textPrimary)

            FlowLayout(spacing: 6) {
                ForEach(skill.items.components(separatedBy: ","), id: \.self) { item in
                    Text(item.trimmingCharacters(in: .whitespaces))
                        .font(LapseTheme.captionFont)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LapseTheme.background)
                        .cornerRadius(LapseTheme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LapseTheme.cornerRadius)
                                .stroke(LapseTheme.border, lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .polaroidCard(index: index)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
