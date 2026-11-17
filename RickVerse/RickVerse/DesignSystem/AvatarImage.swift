import SwiftUI

struct AvatarImage: View {
    let url: URL

    let label: String
    var size: CGFloat? = 56
    var cornerRadius: CGFloat = 12

    var body: some View {
        Color(.secondarySystemFill)
            .frame(width: size, height: size)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "person.crop.square")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    case .empty:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }
}
