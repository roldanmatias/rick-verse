import Domain
import Presentation
import SwiftUI

struct EpisodeDetailScreen: View {
    @State private var viewModel: EpisodeDetailViewModel
    @Environment(\.dataSource) private var dataSource

    @ScaledMetric(relativeTo: .caption) private var minimumCellWidth: CGFloat = 100

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minimumCellWidth), spacing: 12, alignment: .top)]
    }

    init(viewModel: EpisodeDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: Route.episode(id: viewModel.id).url)
                }
                ToolbarItem(placement: .topBarTrailing) { DataSourceBadge(source: dataSource) }
            }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            detail(EpisodeDetail(episode: .placeholder(1), cast: (1...6).map { .placeholder($0) }))
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
        case let .loaded(episodeDetail):
            detail(episodeDetail)
                .navigationTitle(episodeDetail.episode.code)
        case let .failed(error):
            ErrorStateView(error: error) { await viewModel.retry() }
        }
    }

    private func detail(_ detail: EpisodeDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.episode.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(detail.episode.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let date = detail.episode.airDateText(.long) {
                        Label(date, systemImage: "calendar")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Characters (\(detail.cast.count))")
                    .font(.headline)
                    .padding(.top, 8)

                if detail.cast.isEmpty {
                    ContentUnavailableView(
                        "No characters", systemImage: "person.3",
                        description: Text("Nobody is listed for this episode.")
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(detail.cast) { member in
                            NavigationLink(value: Route.castMember(id: member.id)) {
                                CastGridCell(member: member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

private struct CastGridCell: View {
    let member: CastMember

    var body: some View {
        VStack(spacing: 6) {
            AvatarImage(url: member.imageURL, label: member.name, size: nil)
            Text(member.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        EpisodeDetailScreen(viewModel: ViewModelFactory.preview().makeEpisodeDetail(1))
    }
}
