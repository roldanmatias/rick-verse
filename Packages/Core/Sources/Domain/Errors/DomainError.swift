/// The only error type that crosses the Domain boundary.
///
/// Every data layer translates its own failures (`URLError`, `DecodingError`, HTTP status
/// codes, Apollo errors) into one of these cases. The enum is closed, so a ViewModel can
/// `switch` over it exhaustively, and the compiler tells you when a case is added.
public enum DomainError: Error, Equatable, Sendable {
    /// There's no network connection.
    case offline
    /// The request took too long.
    case timeout
    /// The requested resource doesn't exist (HTTP 404, or a GraphQL `null` result).
    case notFound
    /// The server failed (HTTP 5xx, or a GraphQL `errors` payload).
    case server
    /// The response arrived but couldn't be decoded or mapped.
    case invalidData
    /// The task was cancelled. The UI should usually ignore this case and not show an error.
    case cancelled
    /// Anything that doesn't fit a more specific case.
    case unknown
}
