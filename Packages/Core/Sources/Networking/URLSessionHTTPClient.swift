import Foundation
import os

/// The ``HTTPClient`` implementation built on `URLSession`.
///
/// For each call it builds the `URLRequest`, runs it through the middleware chain,
/// validates the status code, and decodes the body. It's a `struct` with only `Sendable`
/// stored properties, so its `Sendable` conformance is checked by the compiler, not promised.
public struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let middlewares: [any RequestMiddleware]
    private let decoder: JSONDecoder

    private static let logger = Logger(subsystem: "RickVerse", category: "HTTPClient")

    /// - Parameters:
    ///   - baseURL: Prefixed to every endpoint path, for example `https://rickandmortyapi.com/api`.
    ///   - session: Inject a session whose configuration uses a stub protocol in tests.
    ///   - middlewares: Run in array order: the first one sees the request first and the response last.
    ///   - decoder: Defaults to ``Foundation/JSONDecoder/rickVerse``.
    public init(
        baseURL: URL,
        session: URLSession = .shared,
        middlewares: [any RequestMiddleware] = [],
        decoder: JSONDecoder = .rickVerse
    ) {
        self.baseURL = baseURL
        self.session = session
        self.middlewares = middlewares
        self.decoder = decoder
    }

    public func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        let request = try endpoint.urlRequest(baseURL: baseURL)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await execute(request)
        } catch {
            throw NetworkError(error)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw .http(status: response.statusCode, body: data)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            Self.logger.error("Decoding \(Response.self, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw NetworkError(error)
        }
    }

    private func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let session = self.session
        let terminal: NextHandler = { request in
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            return (data, http)
        }

        let chain = middlewares.reversed().reduce(terminal) { next, middleware -> NextHandler in
            { request in try await middleware.intercept(request, next: next) }
        }
        return try await chain(request)
    }
}
