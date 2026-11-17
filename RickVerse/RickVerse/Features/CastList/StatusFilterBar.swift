import Domain
import SwiftUI

struct StatusFilterBar: View {
    @Binding var selection: CastMember.Status?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", value: nil)
                ForEach(CastMember.Status.allCases, id: \.self) { status in
                    chip(status.label, value: status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ title: String, value: CastMember.Status?) -> some View {
        let isSelected = selection == value
        return Button {
            selection = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: .capsule)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: CastMember.Status? = .alive
    StatusFilterBar(selection: $selection)
}
