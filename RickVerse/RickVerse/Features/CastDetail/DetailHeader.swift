import Domain
import SwiftUI

struct DetailHeader: View {
    let member: CastMember

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color(.secondarySystemFill)
                .frame(height: 280)
                .overlay {
                    AsyncImage(url: member.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.clear
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .accessibilityHidden(true)

            Text(member.name)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            StatusBadge(status: member.status)
                .font(.title3)
        }
        .padding(.vertical, 8)
    }
}
