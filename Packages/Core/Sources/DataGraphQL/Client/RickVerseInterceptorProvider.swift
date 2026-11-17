import Apollo
import ApolloAPI
import Networking

struct RickVerseInterceptorProvider: InterceptorProvider {
    let log: NetworkLog?

    func graphQLInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any GraphQLInterceptor] {
        DefaultInterceptorProvider.shared.graphQLInterceptors(for: operation) + [ClientHeadersInterceptor()]
    }

    func httpInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any HTTPInterceptor] {
        let metrics: [any HTTPInterceptor] = log.map { [MetricsInterceptor(log: $0, operationName: Operation.operationName)] } ?? []
        return metrics + DefaultInterceptorProvider.shared.httpInterceptors(for: operation)
    }
}
