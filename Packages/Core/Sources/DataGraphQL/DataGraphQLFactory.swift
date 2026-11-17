import Apollo
import Domain
import Foundation
import Networking

/// The repositories the GraphQL data source provides.
public struct GraphQLRepositories: Sendable {
    public let cast: any CastRepository
    public let episodes: any EpisodeRepository
}

/// One Apollo stack (store, client, interceptors) for the app's lifetime: the **public** face of
/// `DataGraphQL`, together with ``DataGraphQLFactory``.
///
/// Repositories for different ``FetchPolicy`` values share the same normalized cache, so changing
/// the policy in Settings never throws the cache away. Everything Apollo stays `internal` (ADR 0005).
public final class GraphQLDataSource: Sendable {
    private let apollo: ApolloClient

    /// - Parameters:
    ///   - endpoint: The GraphQL endpoint.
    ///   - urlSession: Inject a stubbed session in tests.
    ///   - log: Every network round trip is recorded here (not cache hits).
    public init(
        endpoint: URL = DataGraphQLFactory.defaultEndpoint,
        urlSession: URLSession = .shared,
        log: NetworkLog? = nil
    ) {
        apollo = ApolloFactory.makeClient(
            endpoint: endpoint, urlSession: urlSession,
            store: ApolloStore(cache: InMemoryNormalizedCache()), log: log
        )
    }

    public func repositories(policy: FetchPolicy) -> GraphQLRepositories {
        let client = ApolloGraphQLClient(apollo: apollo)
        return GraphQLRepositories(
            cast: GraphQLCastRepository(client: client, policy: policy),
            episodes: GraphQLEpisodeRepository(client: client, policy: policy)
        )
    }

    /// Empties the normalized cache. The next read with any policy goes to the network.
    public func clearCache() async throws {
        try await apollo.clearCache()
    }
}

/// A one-line entry point for when a single policy is enough (tests, previews).
public enum DataGraphQLFactory {
    public static let defaultEndpoint = URL(string: "https://rickandmortyapi.com/graphql")!

    public static func makeRepositories(
        endpoint: URL = defaultEndpoint,
        urlSession: URLSession = .shared,
        policy: FetchPolicy = .networkFirst,
        log: NetworkLog? = nil
    ) -> GraphQLRepositories {
        GraphQLDataSource(endpoint: endpoint, urlSession: urlSession, log: log).repositories(policy: policy)
    }
}
