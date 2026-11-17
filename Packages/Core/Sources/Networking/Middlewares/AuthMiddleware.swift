import Foundation

/// Attaches `Authorization: Bearer <token>`, and on a 401 refreshes the token once and retries.
///
/// > Note: This is an exercise. The Rick and Morty API has no auth.
///
/// Retrying a `POST` here is safe, unlike in ``RetryMiddleware``, because a 401 means the
/// server rejected the request before acting on it. The original request is retried at most
/// once, so a server that keeps answering 401 can't cause a loop. If the refresh itself fails,
/// the original 401 response is returned, and the app should treat that as "sign in again".
public struct AuthMiddleware: RequestMiddleware {
    private let tokenStore: TokenStore

    public init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
    }

    public func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse) {
        let token = try await tokenStore.currentToken()
        let (data, response) = try await next(Self.authorized(request, token: token))
        guard response.statusCode == 401 else { return (data, response) }

        let freshToken: String
        do {
            freshToken = try await tokenStore.refreshedToken(replacing: token)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return (data, response)
        }
        return try await next(Self.authorized(request, token: freshToken))
    }

    private static func authorized(_ request: URLRequest, token: String?) -> URLRequest {
        var request = request
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
