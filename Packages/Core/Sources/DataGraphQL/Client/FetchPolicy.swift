/// How a GraphQL read uses Apollo's normalized cache. It's a user setting (Settings → GraphQL).
///
/// It's our own enum, so neither the app nor the Domain ever names an Apollo type. It maps to
/// Apollo's `CachePolicy.Query` types inside `ApolloGraphQLClient` (internal).
public enum FetchPolicy: String, Sendable, CaseIterable, Identifiable {
    /// Use the cache if it can answer the whole query, otherwise go to the network. Opening the
    /// same character twice makes **zero** requests the second time.
    case cacheFirst
    /// Try the network first, and fall back to the cache if the request fails (offline resilience).
    case networkFirst
    /// Always go to the network. The response is still written to the cache.
    case networkOnly
    /// Stale-while-revalidate: the cached result immediately, then the network result. Only
    /// streaming reads (the character detail) can yield twice. Single-result reads (lists)
    /// behave like ``networkFirst``.
    case cacheAndNetwork

    public var id: Self { self }
}
