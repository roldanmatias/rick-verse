import Apollo
import ApolloAPI
import Foundation
import os

struct ApolloGraphQLClient: GraphQLClient {
    let apollo: ApolloClient

    private static let logger = Logger(subsystem: "RickVerse", category: "GraphQL")

    func fetch<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) async throws -> Query.Data
    where Query.ResponseFormat == SingleResponseFormat {
        let response = try await apollo.fetch(query: query, cachePolicy: policy.singleResponsePolicy)
        return try Self.data(from: response)
    }

    func fetchUpdates<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) -> AsyncThrowingStream<Query.Data, any Error>
    where Query.ResponseFormat == SingleResponseFormat {
        guard policy == .cacheAndNetwork else {
            return AsyncThrowingStream { continuation in
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

        let apollo = self.apollo
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await response in try apollo.fetch(query: query, cachePolicy: .cacheAndNetwork) {
                        continuation.yield(try Self.data(from: response))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func data<Query: GraphQLQuery>(from response: GraphQLResponse<Query>) throws -> Query.Data {
        if let errors = response.errors, !errors.isEmpty {
            logger.warning(
                "\(Query.operationName, privacy: .public) returned partial errors: \(errors.map(\.description), privacy: .public)")
        }
        guard let data = response.data else {
            throw GraphQLClientError.noData(errors: response.errors?.map(\.description) ?? [])
        }

        return data
    }
}

extension FetchPolicy {
    var singleResponsePolicy: CachePolicy.Query.SingleResponse {
        switch self {
        case .cacheFirst: .cacheFirst
        case .networkFirst, .cacheAndNetwork: .networkFirst
        case .networkOnly: .networkOnly
        }
    }
}
