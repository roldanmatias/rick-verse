import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable {
        case characters
        case episodes
        case settings
    }

    @Environment(\.viewModelFactory) private var factory
    @Environment(\.dataSource) private var dataSource
    @State private var selection: Tab = .characters
    @State private var charactersPath = NavigationPath()
    @State private var episodesPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack(path: $charactersPath) {
                CastListScreen(viewModel: factory.makeCastList())
                    .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
            }

            .id(dataSource)
            .tabItem { Label("Characters", systemImage: "person.3") }
            .tag(Tab.characters)

            NavigationStack(path: $episodesPath) {
                EpisodeListScreen(viewModel: factory.makeEpisodeList())
                    .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
            }
            .id(dataSource)
            .tabItem { Label("Episodes", systemImage: "tv") }
            .tag(Tab.episodes)

            NavigationStack(path: $settingsPath) {
                SettingsScreen()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
        .onChange(of: dataSource) {
            charactersPath = NavigationPath()
            episodesPath = NavigationPath()
        }
        .onOpenURL { url in
            guard let route = Route(url: url) else { return }
            open(route)
        }
    }

    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selection },
            set: { tapped in
                if tapped == selection {
                    popToRoot(tapped)
                }
                selection = tapped
            }
        )
    }

    private func popToRoot(_ tab: Tab) {
        switch tab {
        case .characters: charactersPath = NavigationPath()
        case .episodes: episodesPath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        }
    }

    private func open(_ route: Route) {
        switch route {
        case .castMember:
            selection = .characters
            charactersPath.append(route)
        case .episode:
            selection = .episodes
            episodesPath.append(route)
        }
    }
}

struct RouteDestination: View {
    let route: Route
    @Environment(\.viewModelFactory) private var factory

    var body: some View {
        switch route {
        case let .castMember(id):
            CastDetailScreen(viewModel: factory.makeCastDetail(id))
        case let .episode(id):
            EpisodeDetailScreen(viewModel: factory.makeEpisodeDetail(id))
        }
    }
}

#Preview {
    RootTabView()
        .environment(\.viewModelFactory, .preview())
}
