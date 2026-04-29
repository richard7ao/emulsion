import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(EmulsionTheme.headlineFont)
            .foregroundStyle(EmulsionTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, EmulsionTheme.cardPadding)
            .padding(.top, EmulsionTheme.sectionSpacing)
            .padding(.bottom, 8)
    }
}
