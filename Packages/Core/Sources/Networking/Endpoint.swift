import Foundation

/// Describes one request, typed by the response it decodes to.
///
/// An endpoint knows nothing about hosts or sessions. ``HTTPClient`` supplies the base URL,
/// so the same endpoint works against production, staging, or a test stub.
public struct Endpoint<Response: Decodable & Sendable>: Sendable {
    /// The path relative to the client's base URL, for example `"character"` or `"episode/1,2,3"`.
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

extension Endpoint {
    /// Builds the `URLRequest` for this endpoint against `baseURL`.
    ///
    /// Query values are percent-encoded by `URLComponents`, with one fix: `URLComponents`
    /// leaves `+` alone, but many servers decode `+` in a query as a space, so it's encoded
    /// as `%2B` here.
    public func urlRequest(baseURL: URL) throws(NetworkError) -> URLRequest {
        let url = baseURL.appending(path: path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw .invalidRequest
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let finalURL = components.url else { throw .invalidRequest }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if body != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
