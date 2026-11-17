import Foundation

/// Adds headers every request should carry, without overwriting headers the endpoint set itself.
public struct DefaultHeadersMiddleware: RequestMiddleware {
    private let headers: [String: String]

    public init(
        headers: [String: String] = [
            "Accept": "application/json",
            "User-Agent": "RickVerse/1.0 (iOS)",
        ]
    ) {
        self.headers = headers
    }

    public func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse) {
        var request = request
        for (field, value) in headers where request.value(forHTTPHeaderField: field) == nil {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return try await next(request)
    }
}
