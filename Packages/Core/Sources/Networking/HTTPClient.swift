/// Sends an ``Endpoint`` and returns its decoded response.
///
/// Data layers depend on this protocol rather than on `URLSession`, so repository tests can
/// swap in a fake client, or a real client with a stubbed session.
public protocol HTTPClient: Sendable {
    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response
}
