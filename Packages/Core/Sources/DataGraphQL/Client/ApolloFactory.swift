import Apollo
import Foundation
import Networking

enum ApolloFactory {
    static func makeClient(endpoint: URL, urlSession: URLSession, store: ApolloStore, log: NetworkLog? = nil) -> ApolloClient {
        let transport = RequestChainNetworkTransport(
            urlSession: urlSession,
            interceptorProvider: RickVerseInterceptorProvider(log: log),
            store: store,
            endpointURL: endpoint
        )
        return ApolloClient(networkTransport: transport, store: store)
    }
}
