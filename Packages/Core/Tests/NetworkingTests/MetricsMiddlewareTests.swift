import Foundation
import Networking
import Testing

struct MetricsMiddlewareTests {
    @Test func recordsSuccessfulRequest() async throws {
        let log = NetworkLog()
        let next: NextHandler = { _ in (Data("12345".utf8), httpResponse(200)) }

        _ = try await MetricsMiddleware(log: log).intercept(getRequest(), next: next)

        let event = try #require(await log.events.first)
        #expect(event.source == .rest)
        #expect(event.label == "GET /api/character")
        #expect(event.status == 200)
        #expect(event.bytes == 5)
    }

    @Test func recordsFailureWithoutStatus() async throws {
        let log = NetworkLog()
        let next: NextHandler = { _ in throw URLError(.timedOut) }

        await #expect(throws: URLError(.timedOut)) {
            try await MetricsMiddleware(log: log).intercept(getRequest(), next: next)
        }

        let event = try #require(await log.events.first)
        #expect(event.status == nil)
    }

    @Test("A cancelled request is logged as cancelled, not as a failure")
    func recordsCancellation() async throws {
        let log = NetworkLog()
        let next: NextHandler = { _ in throw URLError(.cancelled) }

        await #expect(throws: URLError(.cancelled)) {
            try await MetricsMiddleware(log: log).intercept(getRequest(), next: next)
        }

        let event = try #require(await log.events.first)
        #expect(event.cancelled)
        #expect(event.status == nil)
    }

    @Test func failureIsNotCancellation() async throws {
        let log = NetworkLog()
        let next: NextHandler = { _ in throw URLError(.notConnectedToInternet) }
        _ = try? await MetricsMiddleware(log: log).intercept(getRequest(), next: next)
        #expect(await log.events.first?.cancelled == false)
    }

    @Test func logDropsOldestBeyondCapacity() async {
        let log = NetworkLog(capacity: 2)
        for status in [200, 201, 202] {
            await log.record(NetworkEvent(source: .rest, label: "x", status: status, duration: .zero, bytes: 0))
        }
        #expect(await log.events.map(\.status) == [201, 202])
    }
}
