import SwiftUI

struct DataSourceBadge: View {
    let source: DataSource

    var body: some View {
        Text(source.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(source == .rest ? Color.blue.opacity(0.15) : Color.pink.opacity(0.15), in: .capsule)
            .foregroundStyle(source == .rest ? Color.blue : Color.pink)
            .accessibilityLabel("Data source: \(source.title)")
    }
}
