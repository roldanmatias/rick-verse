import Apollo
import Domain
import Foundation
import os

enum GraphQLErrorMapper {
    private static let logger = Logger(subsystem: "RickVerse", category: "GraphQL")

    static func map(_ error: any Error) -> DomainError {
        switch error {
        case let error as DomainError:
            return error
        case is CancellationError:
            return .cancelled
        case let error as URLError:
            switch error.code {
            case .cancelled: return .cancelled
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: return .offline
            case .timedOut: return .timeout
            default: return logged(error, as: .unknown)
            }
        case let error as ResponseCodeInterceptor.ResponseCodeError:

            return error.response.statusCode == 408 ? .timeout : .server
        case ApolloClient.Error.noResults:

            return .server
        case let GraphQLClientError.transport(underlying):
            return map(underlying)
        case GraphQLClientError.noData:
            return .server
        default:
            return logged(error, as: .unknown)
        }
    }

    private static func logged(_ error: any Error, as domainError: DomainError) -> DomainError {
        logger.error(
            "Unmapped GraphQL error → \(String(describing: domainError), privacy: .public): \(String(describing: error), privacy: .public)")
        return domainError
    }
}
