/// The HTTP methods the client can send.
public enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    /// Whether sending the request several times has the same effect as sending it once.
    ///
    /// ``RetryMiddleware`` only retries idempotent methods. A retried `POST` could, for
    /// example, create two orders, unless the API supports an idempotency key.
    /// `PATCH` isn't guaranteed to be idempotent (think `{"op": "increment"}`), so it isn't retried.
    public var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: true
        case .post, .patch: false
        }
    }
}
