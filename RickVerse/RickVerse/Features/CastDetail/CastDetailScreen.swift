import Domain
import Presentation
import SwiftUI

struct CastDetailScreen: View {
    @State private var viewModel: CastDetailViewModel

    @State private var expandedSeasons: Set<Int> = []
    @Environment(\.dataSource) private var dataSource

    init(viewModel: CastDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: Route.castMember(id: viewModel.id).url)
                }
                ToolbarItem(placement: .topBarTrailing) { DataSourceBadge(source: dataSource) }
            }
            .task { await viewModel.load() }
            .onChange(of: viewModel.episodesBySeason.first?.season, initial: true) { _, first in

                if let first, expandedSeasons.isEmpty {
                    expandedSeasons = [first]
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            detailList(.placeholder)
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
        case let .loaded(detail):
            detailList(detail)
                .navigationTitle(detail.member.name)
        case let .failed(error):
            ErrorStateView(error: error) { await viewModel.retry() }
        }
    }

    private func detailList(_ detail: CastMemberDetail) -> some View {
        List {
            Section {
                DetailHeader(member: detail.member)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Info") {
                LabeledContent("Species", value: detail.member.species)
                LabeledContent("Gender", value: detail.gender)
                LabeledContent("Origin", value: detail.originName)
                LabeledContent("Last seen", value: detail.locationName)
            }

            if viewModel.episodesBySeason.isEmpty {
                Section("Episodes") {
                    Text("No episodes")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Episodes (\(detail.episodes.count))") {
                    ForEach(viewModel.episodesBySeason) { section in
                        DisclosureGroup(isExpanded: isExpanded(section.season)) {
                            ForEach(section.episodes) { episode in
                                NavigationLink(value: Route.episode(id: episode.id)) {
                                    EpisodeRow(episode: episode)
                                }
                            }
                        } label: {
                            Text("Season \(section.season)")
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func isExpanded(_ season: Int) -> Binding<Bool> {
        Binding(
            get: { expandedSeasons.contains(season) },
            set: { isOpen in
                if isOpen {
                    expandedSeasons.insert(season)
                } else {
                    expandedSeasons.remove(season)
                }
            }
        )
    }
}

#Preview("Loaded") {
    NavigationStack {
        CastDetailScreen(viewModel: ViewModelFactory.preview().makeCastDetail(1))
    }
}

#Preview("Not found") {
    NavigationStack {
        CastDetailScreen(
            viewModel: ViewModelFactory.preview(
                cast: PreviewCastRepository(detailResult: .failure(.notFound))
            ).makeCastDetail(1))
    }
}
