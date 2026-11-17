/// Holds the bearer token and refreshes it **at most once at a time** (single-flight).
///
/// > Note: This is an exercise. The Rick and Morty API has no auth.
///
/// Picture five requests that all get a 401 at the same moment. Without coordination, each
/// one would start its own refresh, and with rotating refresh tokens, the second refresh
/// would invalidate the first. Here the first caller starts a refresh `Task` and the others
/// await that same task. The `actor` makes "is a refresh already running?" a race-free check.
public actor TokenStore {
    public typealias Refresh = @Sendable () async throws -> String

    private var token: String?
    private var refreshTask: Task<String, any Error>?
    private let refresh: Refresh

    /// - Parameters:
    ///   - token: The current token, if one is already known (for example, from the Keychain).
    ///   - refresh: Fetches a new token, for example by calling `/oauth/token` with a refresh token.
    public init(token: String? = nil, refresh: @escaping Refresh) {
        self.token = token
        self.refresh = refresh
    }

    /// The token to attach now. If a refresh is running, waits for it to finish.
    public func currentToken() async throws -> String? {
        if let refreshTask {
            return try await refreshTask.value
        }
        return token
    }

    /// Returns a fresh token, starting a refresh only if one is actually needed.
    ///
    /// - Parameter rejected: The token the server just rejected. If the stored token already
    ///   differs from it, another request refreshed in the meantime, and that token is returned
    ///   without refreshing again.
    public func refreshedToken(replacing rejected: String?) async throws -> String {
        if let token, token != rejected {
            return token
        }
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { try await refresh() }
        refreshTask = task

        defer { refreshTask = nil }
        do {
            let newToken = try await task.value
            token = newToken
            return newToken
        } catch {
            token = nil
            throw error
        }
    }
}
