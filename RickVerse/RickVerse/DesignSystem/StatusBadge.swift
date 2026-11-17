import Domain
import SwiftUI

struct StatusBadge: View {
    let status: CastMember.Status

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(status.label)
        }
    }
}

extension CastMember.Status {
    var label: String {
        switch self {
        case .alive: "Alive"
        case .dead: "Dead"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .alive: .green
        case .dead: .red
        case .unknown: .gray
        }
    }
}
