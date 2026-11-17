import Domain
import SwiftUI

struct EpisodeRow: View {
    enum Layout {
        case inline

        case stacked
    }

    let episode: Episode
    var layout: Layout = .inline
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    code
                    Text(episode.name)
                    date(.long)
                }
            } else {
                switch layout {
                case .inline:
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        code
                        Text(episode.name)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        date(.abbreviated)
                    }
                case .stacked:
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        code
                        VStack(alignment: .leading, spacing: 2) {
                            Text(episode.name)
                            date(.long)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var code: some View {
        Text(episode.code)
            .font(.subheadline.monospaced())
            .foregroundStyle(.secondary)
            .fixedSize()
    }

    @ViewBuilder
    private func date(_ style: Date.FormatStyle.DateStyle) -> some View {
        if let text = episode.airDateText(style) {
            Text(text)
                .font(layout == .inline && !typeSize.isAccessibilitySize ? .footnote : .subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        ForEach(Episode.samples) { EpisodeRow(episode: $0) }
        ForEach(Episode.samples) { EpisodeRow(episode: $0, layout: .stacked) }
    }
}

#Preview("AX5") {
    List {
        ForEach(Episode.samples) { EpisodeRow(episode: $0) }
    }
    .dynamicTypeSize(.accessibility5)
}
