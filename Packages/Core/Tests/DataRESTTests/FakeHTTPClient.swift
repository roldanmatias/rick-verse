import Foundation
import Networking

actor FakeHTTPClient: HTTPClient {
    private(set) var paths: [String] = []
    private(set) var peakInFlight = 0
    private var inFlight = 0

    private let latency: Duration
    private let respond: @Sendable (String) throws(NetworkError) -> Data

    init(latency: Duration = .milliseconds(5), respond: @escaping @Sendable (String) throws(NetworkError) -> Data) {
        self.latency = latency
        self.respond = respond
    }

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        paths.append(endpoint.path)
        inFlight += 1
        peakInFlight = max(peakInFlight, inFlight)
        defer { inFlight -= 1 }

        do {
            try await Task.sleep(for: latency)
        } catch {
            throw .cancelled
        }
        let data = try respond(endpoint.path)
        do {
            return try JSONDecoder.rickVerse.decode(Response.self, from: data)
        } catch {
            throw NetworkError(error)
        }
    }
}
