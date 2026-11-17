import Foundation
import Networking
import TestSupport
import Testing

struct AuthMiddlewareTests {
    final class FakeServer: @unchecked Sendable {
        private let lock = NSLock()
        private var _seen: [String?] = []
        let validToken: String

        init(validToken: String) { self.validToken = validToken }

        var seen: [String?] { lock.withLock { _seen } }

        var handler: NextHandler {
            { [self] request in
                let header = request.value(forHTTPHeaderField: "Authorization")
                lock.withLock { _seen.append(header) }
                return (Data(), httpResponse(header == "Bearer \(validToken)" ? 200 : 401))
            }
        }
    }

    @Test func attachesBearerToken() async throws {
        let server = FakeServer(validToken: "abc")
        let sut = AuthMiddleware(tokenStore: TokenStore(token: "abc") { "unused" })

        let (_, response) = try await sut.intercept(getRequest(), next: server.handler)

        #expect(response.statusCode == 200)
        #expect(server.seen == ["Bearer abc"])
    }

    @Test("A 401 refreshes and retries the original request once")
    func refreshesOn401() async throws {
        let server = FakeServer(validToken: "fresh")
        let sut = AuthMiddleware(tokenStore: TokenStore(token: "stale") { "fresh" })

        let (_, response) = try await sut.intercept(getRequest(.post), next: server.handler)

        #expect(response.statusCode == 200)
        #expect(server.seen == ["Bearer stale", "Bearer fresh"])
    }

    @Test("Ten concurrent 401s trigger exactly one refresh")
    func singleFlightRefresh() async throws {
        let server = FakeServer(validToken: "fresh")
        let refreshes = Recorder<Int>()
        let store = TokenStore(token: "stale") {
            await refreshes.append(1)
            try await Task.sleep(for: .milliseconds(50))
            return "fresh"
        }
        let sut = AuthMiddleware(tokenStore: store)

        let statuses = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<10 {
                group.addTask { try await sut.intercept(getRequest(), next: server.handler).1.statusCode }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(statuses == Array(repeating: 200, count: 10))
        #expect(await refreshes.values.count == 1)
    }

    @Test("If the server keeps answering 401, there's no loop")
    func retriesOnlyOnce() async throws {
        let server = FakeServer(validToken: "never")
        let sut = AuthMiddleware(tokenStore: TokenStore(token: "stale") { "still-wrong" })

        let (_, response) = try await sut.intercept(getRequest(), next: server.handler)

        #expect(response.statusCode == 401)
        #expect(server.seen.count == 2)
    }

    @Test("A failed refresh returns the original 401")
    func refreshFailure() async throws {
        struct RefreshFailed: Error {}
        let server = FakeServer(validToken: "fresh")
        let sut = AuthMiddleware(tokenStore: TokenStore(token: "stale") { throw RefreshFailed() })

        let (_, response) = try await sut.intercept(getRequest(), next: server.handler)

        #expect(response.statusCode == 401)
        #expect(server.seen == ["Bearer stale"])
    }
}
