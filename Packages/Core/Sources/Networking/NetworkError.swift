import Foundation

/// Transport-level failures.
///
/// This module knows nothing about the Domain. Each data layer maps these cases to
/// `DomainError` itself (for example, 404 → `.notFound`).
public enum NetworkError: Error, Equatable, Sendable {
    /// The endpoint couldn't be turned into a valid `URLRequest`.
    case invalidRequest
    case offline
    case timeout
    /// The task was cancelled. This isn't a failure to show the user.
    case cancelled
    /// The server answered with a non-2xx status. The body is kept for error payloads.
    case http(status: Int, body: Data)
    /// The response body didn't match the expected type. The string names the failing key path.
    case decoding(String)
    /// Any other transport failure (TLS, DNS, a malformed response…).
    case transport(String)
}

extension NetworkError {
    /// The one place where arbitrary errors become ``NetworkError``.
    public init(_ error: any Error) {
        switch error {
        case let error as NetworkError:
            self = error
        case is CancellationError:
            self = .cancelled
        case let error as URLError:
            switch error.code {
            case .cancelled:
                self = .cancelled
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                self = .offline
            case .timedOut:
                self = .timeout
            default:
                self = .transport(String(describing: error))
            }
        case let error as DecodingError:
            self = .decoding(String(describing: error))
        default:
            self = .transport(String(describing: error))
        }
    }
}
