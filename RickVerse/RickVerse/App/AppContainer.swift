import DataGraphQL
import DataREST
import Domain
import Foundation
import Networking
import Presentation

@MainActor
final class AppContainer {
    enum LaunchMode: Equatable {
        case live
        case uiTesting(UITestScenario)

        static func from(_ arguments: [String]) -> LaunchMode {
            guard arguments.contains("-uiTesting") else { return .live }
            let name = arguments.firstIndex(of: "-uiTestingScenario").flatMap { index in
                arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
            }
            return .uiTesting(name.flatMap(UITestScenario.init(rawValue:)) ?? .normal)
        }
    }

    let mode: LaunchMode

    let networkLog = NetworkLog()

    private static let restBaseURL = URL(string: "https://rickandmortyapi.com/api")!

    init(mode: LaunchMode = .from(ProcessInfo.processInfo.arguments)) {
        self.mode = mode
    }

    private struct Repositories {
        let cast: any CastRepository
        let episodes: any EpisodeRepository
    }

    private lazy var rest: Repositories = {
        let client = URLSessionHTTPClient(
            baseURL: Self.restBaseURL,
            session: .shared,

            middlewares: [
                DefaultHeadersMiddleware(),
                MetricsMiddleware(log: networkLog),
                RetryMiddleware(),
                LoggingMiddleware(),
            ]
        )
        return Repositories(
            cast: RESTCastRepository(client: client, episodeLoading: .batch),
            episodes: RESTEpisodeRepository(client: client)
        )
    }()

    private lazy var graphQL = GraphQLDataSource(log: networkLog)

    func viewModelFactory(for source: DataSource, policy: FetchPolicy) -> ViewModelFactory {
        let repositories: Repositories
        switch (mode, source) {
        case let (.uiTesting(scenario), _):
            let failure: DomainError? = scenario == .offline ? .offline : nil
            let isEmpty = scenario == .empty
            repositories = Repositories(
                cast: PreviewCastRepository(delay: .milliseconds(200), failure: failure, isEmpty: isEmpty),
                episodes: PreviewEpisodeRepository(delay: .milliseconds(200), failure: failure, isEmpty: isEmpty)
            )
        case (.live, .rest):
            repositories = rest
        case (.live, .graphQL):
            let graphQLRepositories = graphQL.repositories(policy: policy)
            repositories = Repositories(cast: graphQLRepositories.cast, episodes: graphQLRepositories.episodes)
        }
        let cast = repositories.cast
        let episodes = repositories.episodes
        let log = networkLog
        return ViewModelFactory(
            makeCastList: { CastListViewModel(searchCast: SearchCastUseCase(repository: cast)) },
            makeCastDetail: { CastDetailViewModel(id: $0, getDetail: GetCastMemberDetailUseCase(repository: cast)) },
            makeEpisodeList: { EpisodeListViewModel(getEpisodes: GetEpisodesUseCase(repository: episodes)) },
            makeEpisodeDetail: { EpisodeDetailViewModel(id: $0, getDetail: GetEpisodeDetailUseCase(repository: episodes)) },
            makeNetworkLog: { Self.makeNetworkLogViewModel(log) }
        )
    }

    var actions: AppActions {
        let graphQL = self.graphQL
        return AppActions(clearGraphQLCache: { try await graphQL.clearCache() })
    }

    private static func makeNetworkLogViewModel(_ log: NetworkLog) -> NetworkLogViewModel {
        NetworkLogViewModel(
            updates: {
                let source = log.updates()
                return AsyncStream { continuation in
                    let task = Task {
                        for await events in source {
                            continuation.yield(events.map(NetworkLogEntry.init))
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            clear: { await log.clear() }
        )
    }
}

nonisolated private extension NetworkLogEntry {
    init(_ event: NetworkEvent) {
        self.init(
            id: event.id, timestamp: event.timestamp,
            source: event.source == .rest ? .rest : .graphQL,
            label: event.label, status: event.status, duration: event.duration, bytes: event.bytes,
            cancelled: event.cancelled
        )
    }
}

enum UITestScenario: String {
    case normal

    case offline

    case empty
}
