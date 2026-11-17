import Domain
import SwiftUI

struct CastRow: View {
    let member: CastMember
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let isAccessibilitySize = typeSize.isAccessibilitySize
        let layout =
            isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            AvatarImage(url: member.imageURL, label: member.name)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .lineLimit(isAccessibilitySize ? nil : 1)
                details(stacked: isAccessibilitySize)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)

        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func details(stacked: Bool) -> some View {
        if stacked {
            VStack(alignment: .leading, spacing: 2) {
                StatusBadge(status: member.status)
                Text(member.species)
            }
        } else {
            HStack(spacing: 4) {
                StatusBadge(status: member.status)
                Text("·")
                    .accessibilityHidden(true)
                Text(member.species)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    List(CastMember.samples) { CastRow(member: $0) }
        .listStyle(.plain)
}

#Preview("AX5") {
    List(CastMember.samples) { CastRow(member: $0) }
        .listStyle(.plain)
        .dynamicTypeSize(.accessibility5)
}
