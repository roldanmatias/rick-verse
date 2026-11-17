import Foundation

/// Retries failed idempotent requests with exponential backoff and full jitter.
///
/// - It only retries methods that are ``HTTPMethod/isIdempotent``, so a `POST` is never repeated.
/// - It retries on 408, 429, 5xx, `URLError.timedOut`, and `URLError.networkConnectionLost`.
/// - The delay before retry *n* (counting from 0) is a random value in `0...baseDelay * 2^n`.
///   The randomness is the "full jitter", which keeps thousands of clients from retrying in
///   sync (the "thundering herd").
/// - A `Retry-After` header given in seconds replaces the computed delay.
/// - It checks for cancellation before every retry, and the sleep itself is cancellable.
public struct RetryMiddleware: RequestMiddleware {
    public typealias Sleep = @Sendable (Duration) async throws -> Void
    public typealias Jitter = @Sendable (ClosedRange<Double>) -> Double

    private let maxAttempts: Int
    private let baseDelay: Duration
    private let sleep: Sleep
    private let jitter: Jitter

    /// - Parameters:
    ///   - maxAttempts: The total number of attempts, including the first one.
    ///   - baseDelay: The upper bound of the first retry's delay.
    ///   - sleep: Injected so tests run instantly and can record delays.
    ///   - jitter: Picks a value from a range. Injected so tests are deterministic.
    public init(
        maxAttempts: Int = 3,
        baseDelay: Duration = .milliseconds(500),
        sleep: @escaping Sleep = { try await Task.sleep(for: $0) },
        jitter: @escaping Jitter = { Double.random(in: $0) }
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.sleep = sleep
        self.jitter = jitter
    }

    public func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse) {
        guard HTTPMethod(rawValue: request.httpMethod ?? "GET")?.isIdempotent == true else {
            return try await next(request)
        }

        var attempt = 0
        while true {
            let delay: Duration
            do {
                let (data, response) = try await next(request)
                guard attempt + 1 < maxAttempts, Self.isRetryable(status: response.statusCode) else {
                    return (data, response)
                }
                delay = Self.retryAfter(response) ?? backoff(attempt: attempt)
            } catch {
                guard attempt + 1 < maxAttempts, Self.isRetryable(error) else { throw error }
                delay = backoff(attempt: attempt)
            }

            try Task.checkCancellation()
            try await sleep(delay)
            attempt += 1
        }
    }

    private func backoff(attempt: Int) -> Duration {
        let ceiling = baseDelay * (1 << attempt)
        let seconds = Double(ceiling.components.seconds) + Double(ceiling.components.attoseconds) / 1e18
        return .seconds(jitter(0...seconds))
    }

    static func isRetryable(status: Int) -> Bool {
        status == 408 || status == 429 || (500...599).contains(status)
    }

    static func isRetryable(_ error: any Error) -> Bool {
        guard let error = error as? URLError else { return false }
        return error.code == .timedOut || error.code == .networkConnectionLost
    }

    static func retryAfter(_ response: HTTPURLResponse) -> Duration? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After"),
            let seconds = Double(value.trimmingCharacters(in: .whitespaces)),
            seconds >= 0
        else { return nil }
        return .seconds(seconds)
    }
}
