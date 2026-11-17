import Foundation
import Networking
import TestSupport
import Testing

struct RetryMiddlewareTests {
    private func middleware(_ delays: Recorder<Duration>, jitter: @escaping RetryMiddleware.Jitter = { $0.upperBound }) -> RetryMiddleware {
        RetryMiddleware(baseDelay: .milliseconds(500), sleep: { await delays.append($0) }, jitter: jitter)
    }

    @Test("Backoff doubles each attempt: 0.5 s, then 1 s")
    func exponentialBackoff() async throws {
        let delays = Recorder<Duration>()
        let next = ScriptedNext(.status(500), .status(502), .status(200))

        let (_, response) = try await middleware(delays).intercept(getRequest(), next: next.handler)

        #expect(response.statusCode == 200)
        #expect(await delays.values == [.milliseconds(500), .seconds(1)])
    }

    @Test("Full jitter picks from 0...ceiling: the lower bound is zero")
    func jitterLowerBound() async throws {
        let delays = Recorder<Duration>()
        let next = ScriptedNext(.status(503), .status(503), .status(200))

        _ = try await middleware(delays, jitter: { $0.lowerBound }).intercept(getRequest(), next: next.handler)

        #expect(await delays.values == [.zero, .zero])
    }

    @Test("The real jitter stays within 0...ceiling")
    func defaultJitterStaysInRange() async throws {
        let delays = Recorder<Duration>()
        let sut = RetryMiddleware(maxAttempts: 3, baseDelay: .milliseconds(500), sleep: { await delays.append($0) })

        _ = try await sut.intercept(getRequest(), next: ScriptedNext(.status(503), .status(503), .status(200)).handler)

        let values = await delays.values
        #expect(values.count == 2)
        #expect((Duration.zero ... .milliseconds(500)).contains(values[0]))
        #expect((Duration.zero ... .seconds(1)).contains(values[1]))
    }

    @Test("Retry-After in seconds replaces the computed delay")
    func honorsRetryAfter() async throws {
        let delays = Recorder<Duration>()
        let next = ScriptedNext(.status(429, headers: ["Retry-After": "7"]), .status(200))

        _ = try await middleware(delays).intercept(getRequest(), next: next.handler)

        #expect(await delays.values == [.seconds(7)])
    }

    @Test(arguments: [408, 429, 500, 503, 599])
    func retriesStatus(_ status: Int) async throws {
        let next = ScriptedNext(.status(status), .status(200))
        _ = try await middleware(Recorder()).intercept(getRequest(), next: next.handler)
        #expect(next.calls == 2)
    }

    @Test(arguments: [400, 401, 403, 404, 422])
    func doesNotRetryClientErrors(_ status: Int) async throws {
        let next = ScriptedNext(.status(status), .status(200))
        let (_, response) = try await middleware(Recorder()).intercept(getRequest(), next: next.handler)
        #expect(response.statusCode == status)
        #expect(next.calls == 1)
    }

    @Test(arguments: [URLError.Code.timedOut, .networkConnectionLost])
    func retriesTransientErrors(_ code: URLError.Code) async throws {
        let next = ScriptedNext(.error(URLError(code)), .status(200))
        _ = try await middleware(Recorder()).intercept(getRequest(), next: next.handler)
        #expect(next.calls == 2)
    }

    @Test func doesNotRetryOffline() async {
        let next = ScriptedNext(.error(URLError(.notConnectedToInternet)), .status(200))
        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await middleware(Recorder()).intercept(getRequest(), next: next.handler)
        }
        #expect(next.calls == 1)
    }

    @Test(arguments: [HTTPMethod.post, .patch])
    func doesNotRetryNonIdempotent(_ method: HTTPMethod) async throws {
        let next = ScriptedNext(.status(503), .status(200))
        _ = try await middleware(Recorder()).intercept(getRequest(method), next: next.handler)
        #expect(next.calls == 1)
    }

    @Test(arguments: [HTTPMethod.put, .delete])
    func retriesOtherIdempotentMethods(_ method: HTTPMethod) async throws {
        let next = ScriptedNext(.status(503), .status(200))
        _ = try await middleware(Recorder()).intercept(getRequest(method), next: next.handler)
        #expect(next.calls == 2)
    }

    @Test func stopsBeforeRetryingWhenCancelled() async {
        let next = ScriptedNext(.status(503), .status(200))
        let sut = middleware(Recorder())
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.intercept(getRequest(), next: next.handler)
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(next.calls == 1)
    }
}
