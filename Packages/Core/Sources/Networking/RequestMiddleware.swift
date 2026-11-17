import Foundation

/// The rest of the chain: the next middleware, or the network call itself at the end.
public typealias NextHandler = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

/// One link in the request chain, like a Dio interceptor or an Apollo `HTTPInterceptor`.
///
/// A middleware can change the request before calling `next`, inspect or replace the
/// response afterwards, call `next` more than once (retry), or not call it at all (cache).
/// Middlewares see every response, including non-2xx ones. Status validation happens in
/// the client after the chain, so ``RetryMiddleware`` and ``AuthMiddleware`` can react to
/// a 503 or 401.
public protocol RequestMiddleware: Sendable {
    func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse)
}
