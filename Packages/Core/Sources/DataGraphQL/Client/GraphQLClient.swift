import ApolloAPI

protocol GraphQLClient: Sendable {
    func fetch<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) async throws -> Query.Data
    where Query.ResponseFormat == SingleResponseFormat

    func fetchUpdates<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) -> AsyncThrowingStream<Query.Data, any Error>
    where Query.ResponseFormat == SingleResponseFormat
}

extension GraphQLClient {
    func fetchUpdates<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) -> AsyncThrowingStream<Query.Data, any Error>
    where Query.ResponseFormat == SingleResponseFormat {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try await fetch(query, policy: policy))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
