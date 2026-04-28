import SwiftUI

struct RemoteImage: View {
    let url: URL
    let height: CGFloat
    var width: CGFloat? = nil

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .overlay {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LapseTheme.border.opacity(0.3))
                        .overlay { ProgressView() }
                }
            }
            .clipped()
    }
}
