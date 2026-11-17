import Foundation
import os

/// Logs the method, URL, status, and duration of each request with `os.Logger`.
///
/// It never logs headers or bodies, so a bearer token or other personal data can't leak
/// into the system log. The query string, which can contain search terms, is marked `.private`.
public struct LoggingMiddleware: RequestMiddleware {
    private let logger: Logger

    public init(logger: Logger = Logger(subsystem: "RickVerse", category: "Network")) {
        self.logger = logger
    }

    public func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse) {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path() ?? "?"
        let query = request.url?.query() ?? ""
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let (data, response) = try await next(request)
            let elapsed = clock.now - start
            logger.info(
                "\(method, privacy: .public) \(path, privacy: .public)?\(query, privacy: .private) → \(response.statusCode, privacy: .public) in \(elapsed, privacy: .public), \(data.count, privacy: .public) bytes"
            )
            return (data, response)
        } catch {
            let elapsed = clock.now - start
            logger.error(
                "\(method, privacy: .public) \(path, privacy: .public)?\(query, privacy: .private) failed after \(elapsed, privacy: .public): \(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }
}
