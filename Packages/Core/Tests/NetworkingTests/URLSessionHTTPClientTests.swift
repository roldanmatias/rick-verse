import Foundation
import Networking
import TestSupport
import Testing

struct URLSessionHTTPClientTests {
    private func makeClient(_ stub: StubbedSession, middlewares: [any RequestMiddleware] = []) -> URLSessionHTTPClient {
        URLSessionHTTPClient(baseURL: baseURL, session: stub.session, middlewares: middlewares)
    }

    private let instantRetry = RetryMiddleware(sleep: { _ in })

    @Test func buildsURLWithEncodedQuery() async throws {
        let stub = StubbedSession(.json(heroJSON))
        let endpoint = Endpoint<Hero>(path: "character", queryItems: [URLQueryItem(name: "name", value: "Rick Sanchez")])

        _ = try await makeClient(stub).send(endpoint)

        #expect(
            stub.requests.first?.url?.absoluteString
                == "https://rickandmortyapi.com/api/character?name=Rick%20Sanchez")
    }

    @Test func sendsDefaultHeaders() async throws {
        let stub = StubbedSession(.json(heroJSON))

        _ = try await makeClient(stub, middlewares: [DefaultHeadersMiddleware()]).send(.hero)

        let request = try #require(stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "RickVerse/1.0 (iOS)")
    }

    @Test func endpointHeadersWinOverDefaults() async throws {
        let stub = StubbedSession(.json(heroJSON))
        let endpoint = Endpoint<Hero>(path: "character/1", headers: ["Accept": "application/graphql-response+json"])

        _ = try await makeClient(stub, middlewares: [DefaultHeadersMiddleware()]).send(endpoint)

        #expect(stub.requests.first?.value(forHTTPHeaderField: "Accept") == "application/graphql-response+json")
    }

    @Test func decodes200() async throws {
        let hero = try await makeClient(StubbedSession(.json(heroJSON))).send(.hero)
        #expect(hero == Hero(id: 1, name: "Rick Sanchez"))
    }

    @Test func non2xxBecomesHTTPErrorWithBody() async {
        let body = #"{"error": "Character not found"}"#
        let client = makeClient(StubbedSession(.json(body, status: 404)))

        await #expect(throws: NetworkError.http(status: 404, body: Data(body.utf8))) {
            try await client.send(.hero)
        }
    }

    @Test func badJSONBecomesDecodingError() async {
        let client = makeClient(StubbedSession(.json(#"{"id": "one"}"#)))
        do {
            _ = try await client.send(.hero)
            Issue.record("Expected a throw")
        } catch {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        }
    }

    @Test func offlineMapsToOffline() async {
        let client = makeClient(StubbedSession(.failure(URLError(.notConnectedToInternet))))
        await #expect(throws: NetworkError.offline) { try await client.send(.hero) }
    }

    @Test("503, 503, 200 succeeds on the third call")
    func retriesServerErrors() async throws {
        let stub = StubbedSession(.status(503), .status(503), .json(heroJSON))

        let hero = try await makeClient(stub, middlewares: [instantRetry]).send(.hero)

        #expect(hero.id == 1)
        #expect(stub.requests.count == 3)
    }

    @Test func givesUpAfterMaxAttempts() async {
        let stub = StubbedSession(.status(503))
        let client = makeClient(stub, middlewares: [instantRetry])

        await #expect(throws: NetworkError.http(status: 503, body: Data())) { try await client.send(.hero) }
        #expect(stub.requests.count == 3)
    }

    @Test func doesNotRetry400() async {
        let stub = StubbedSession(.status(400), .json(heroJSON))
        let client = makeClient(stub, middlewares: [instantRetry])

        await #expect(throws: NetworkError.http(status: 400, body: Data())) { try await client.send(.hero) }
        #expect(stub.requests.count == 1)
    }

    @Test func doesNotRetryPOST() async {
        let stub = StubbedSession(.status(503), .json(heroJSON))
        let client = makeClient(stub, middlewares: [instantRetry])

        await #expect(throws: NetworkError.http(status: 503, body: Data())) { try await client.send(.createHero) }
        #expect(stub.requests.count == 1)
        #expect(stub.requests.first?.httpBody == Data(#"{"name":"Rick"}"#.utf8))
    }

    @Test("Cancelling during the backoff yields .cancelled with no retry")
    func cancelDuringBackoff() async throws {
        let stub = StubbedSession(.status(503), .json(heroJSON))

        let client = makeClient(stub, middlewares: [RetryMiddleware(baseDelay: .seconds(60), jitter: { $0.upperBound })])

        let task = Task { try await client.send(.hero) }
        try await waitUntil { stub.requests.count == 1 }
        task.cancel()

        await #expect(throws: NetworkError.cancelled) { try await task.value }
        #expect(stub.requests.count == 1)
    }

    @Test("An already-cancelled task yields .cancelled")
    func cancelBeforeSending() async {
        let stub = StubbedSession(.json(heroJSON))
        let client = makeClient(stub, middlewares: [instantRetry])

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await client.send(.hero)
        }

        await #expect(throws: NetworkError.cancelled) { try await task.value }
        #expect(stub.requests.count <= 1)
    }
}

private func waitUntil(_ condition: @Sendable () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
        try await Task.sleep(for: .milliseconds(10))
    }
    try #require(condition())
}
