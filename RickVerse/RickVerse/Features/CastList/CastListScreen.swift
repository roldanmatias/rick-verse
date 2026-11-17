import Domain
import Presentation
import SwiftUI

struct CastListScreen: View {
    @State private var viewModel: CastListViewModel
    @Environment(\.dataSource) private var dataSource

    init(viewModel: CastListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { DataSourceBadge(source: dataSource) }
            }
            .searchable(text: $viewModel.query, prompt: "Search characters")
            .sensoryFeedback(.selection, trigger: viewModel.statusFilter)
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
            withFilterBar {
                if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    ContentUnavailableView(
                        "No characters", systemImage: "person.3",
                        description: Text("Nobody matches this filter."))
                } else {
                    ContentUnavailableView.search(text: viewModel.query)
                }
            }
        case let .failed(error):
            withFilterBar {
                ErrorStateView(error: error) { await viewModel.retry() }
            }
        }
    }

    private var filterBar: some View {
        StatusFilterBar(selection: $viewModel.statusFilter)
    }

    private var filterRow: some View {
        filterBar
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
    }

    private func withFilterBar(@ViewBuilder _ message: () -> some View) -> some View {
        VStack(spacing: 0) {
            filterBar
            message()
                .frame(maxHeight: .infinity)
        }
    }

    private var list: some View {
        List {
            filterRow
            ForEach(viewModel.items) { member in
                NavigationLink(value: Route.castMember(id: member.id)) {
                    CastRow(member: member)
                }
                .onAppear { viewModel.onItemAppear(member) }
            }
            PaginationFooter(state: viewModel.pagination) { viewModel.retryNextPage() }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var skeleton: some View {
        List {
            filterRow
            ForEach(1...8, id: \.self) { index in
                CastRow(member: .placeholder(index))
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
            }
        }
        .listStyle(.plain)
        .accessibilityLabel("Loading characters")
    }
}

#Preview("Loaded") {
    NavigationStack {
        CastListScreen(viewModel: ViewModelFactory.preview().makeCastList())
    }
}

#Preview("Empty") {
    NavigationStack {
        CastListScreen(
            viewModel: ViewModelFactory.preview(
                cast:
                    PreviewCastRepository(result: .success(Page(items: [], nextPage: nil)))
            ).makeCastList())
    }
}

#Preview("Offline") {
    NavigationStack {
        CastListScreen(
            viewModel: ViewModelFactory.preview(
                cast:
                    PreviewCastRepository(result: .failure(.offline))
            ).makeCastList())
    }
}
