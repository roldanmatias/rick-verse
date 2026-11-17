import Domain
import Presentation
import SwiftUI

struct EpisodeListScreen: View {
    @State private var viewModel: EpisodeListViewModel
    @Environment(\.dataSource) private var dataSource

    init(viewModel: EpisodeListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Episodes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { DataSourceBadge(source: dataSource) }
            }
            .task { await viewModel.onAppear() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .loading:
            skeleton
        case .loaded:
            list
        case .empty:
            ContentUnavailableView("No episodes", systemImage: "tv")
        case let .failed(error):
            ErrorStateView(error: error) { await viewModel.retry() }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section("Season \(section.season)") {
                    ForEach(section.episodes) { episode in
                        NavigationLink(value: Route.episode(id: episode.id)) {
                            EpisodeRow(episode: episode, layout: .stacked)
                        }
                        .onAppear { viewModel.onItemAppear(episode) }
                    }
                }
            }
            PaginationFooter(state: viewModel.pagination, endMessage: "That's every episode 📺") {
                viewModel.retryNextPage()
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var skeleton: some View {
        List {
            Section("Season 0") {
                ForEach(1...8, id: \.self) { index in
                    EpisodeRow(episode: .placeholder(index), layout: .stacked)
                }
            }
        }
        .listStyle(.plain)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .accessibilityLabel("Loading episodes")
    }
}

#Preview {
    NavigationStack {
        EpisodeListScreen(viewModel: ViewModelFactory.preview().makeEpisodeList())
    }
}
