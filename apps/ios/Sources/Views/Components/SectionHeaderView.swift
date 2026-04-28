import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(LapseTheme.headlineFont)
            .foregroundStyle(LapseTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LapseTheme.cardPadding)
            .padding(.top, LapseTheme.sectionSpacing)
            .padding(.bottom, 8)
    }
}
