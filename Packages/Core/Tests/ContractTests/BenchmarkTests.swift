import DataGraphQL
import DataREST
import Domain
import Foundation
import Networking
import Testing

@Suite(.enabled(if: ProcessInfo.processInfo.environment["RUN_BENCHMARKS"] == "1"), .serialized)
struct BenchmarkTests {
    static let runs = 5
    static let restBase = URL(string: "https://rickandmortyapi.com/api")!

    static let coolDown: Duration = .seconds(4)

    struct Measurement {
        var requests: Int
        var milliseconds: Double
        var bytes: Int

        var throttled: Double

        var failures: Int
    }

    private static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    private static func rest(_ loading: RESTCastRepository.EpisodeLoading, log: NetworkLog, session: URLSession)
        -> (cast: RESTCastRepository, episodes: RESTEpisodeRepository)
    {
        let client = URLSessionHTTPClient(
            baseURL: restBase, session: session,
            middlewares: [RetryMiddleware(maxAttempts: 5, baseDelay: .seconds(1)), MetricsMiddleware(log: log)])
        return (RESTCastRepository(client: client, episodeLoading: loading), RESTEpisodeRepository(client: client))
    }

    private static func measure(
        _ name: String,
        prepare: @escaping (NetworkLog, URLSession) async throws -> (@Sendable () async throws -> Void)
    ) async throws -> Measurement {
        var samples: [Measurement] = []
        var failures = 0
        for run in 0...runs {
            try await Task.sleep(for: coolDown)
            let log = NetworkLog()
            let session = session()
            let body = try await prepare(log, session)
            await log.clear()
            let clock = ContinuousClock()
            var failed = false
            let elapsed = await clock.measure {
                do { try await body() } catch {
                    failed = true
                    print("BENCHMARK \(name) run \(run) failed: \(error)")
                }
            }
            let events = await log.events
            guard run > 0 else { continue }
            if failed {
                failures += 1
                continue
            }
            let throttled = events.filter { $0.status == 429 }.count
            samples.append(
                Measurement(
                    requests: events.count - throttled,
                    milliseconds: Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1000,
                    bytes: events.filter { $0.status == 200 }.reduce(0) { $0 + $1.bytes },
                    throttled: Double(throttled),
                    failures: 0
                ))
        }
        let n = Double(max(samples.count, 1))
        return Measurement(
            requests: samples.map(\.requests).max() ?? 0,
            milliseconds: samples.map(\.milliseconds).reduce(0, +) / n,
            bytes: Int(Double(samples.map(\.bytes).reduce(0, +)) / n),
            throttled: samples.map(\.throttled).reduce(0, +) / n,
            failures: failures
        )
    }

    @Test func restVsGraphQL() async throws {
        let sequential = try await Self.measure("sequential") { log, session in
            let cast = Self.rest(.concurrent(maxInFlight: 1), log: log, session: session).cast
            return { _ = try await cast.detail(id: 1) }
        }
        let concurrent = try await Self.measure("concurrent") { log, session in
            let cast = Self.rest(.concurrent(maxInFlight: 6), log: log, session: session).cast
            return { _ = try await cast.detail(id: 1) }
        }
        let batch = try await Self.measure("batch") { log, session in
            let cast = Self.rest(.batch, log: log, session: session).cast
            return { _ = try await cast.detail(id: 1) }
        }
        let gqlNetwork = try await Self.measure("gqlNetwork") { log, session in
            let cast = GraphQLDataSource(urlSession: session, log: log).repositories(policy: .networkOnly).cast
            return { _ = try await cast.detail(id: 1) }
        }
        let gqlCache = try await Self.measure("gqlCache") { log, session in
            let source = GraphQLDataSource(urlSession: session, log: log)
            _ = try await source.repositories(policy: .networkOnly).cast.detail(id: 1)
            let cast = source.repositories(policy: .cacheFirst).cast
            return { _ = try await cast.detail(id: 1) }
        }

        let episodeREST = try await Self.measure("episodeREST") { log, session in
            let episodes = Self.rest(.batch, log: log, session: session).episodes
            return { _ = try await episodes.detail(id: 1) }
        }
        let episodeGQL = try await Self.measure("episodeGQL") { log, session in
            let episodes = GraphQLDataSource(urlSession: session, log: log).repositories(policy: .networkOnly).episodes
            return { _ = try await episodes.detail(id: 1) }
        }
        let episodeGQLCache = try await Self.measure("episodeGQLCache") { log, session in
            let source = GraphQLDataSource(urlSession: session, log: log)
            _ = try await source.repositories(policy: .networkOnly).episodes.detail(id: 1)
            let episodes = source.repositories(policy: .cacheFirst).episodes
            return { _ = try await episodes.detail(id: 1) }
        }

        #expect(sequential.requests == 52)
        #expect(concurrent.requests == 52)
        #expect(batch.requests == 2)
        #expect(gqlNetwork.requests == 1)
        #expect(gqlCache.requests == 0)
        #expect(episodeREST.requests == 2)
        #expect(episodeGQL.requests == 1)
        #expect(episodeGQLCache.requests == 0)

        func ms(_ m: Measurement) -> String { String(format: "%.0f", m.milliseconds) }
        func kb(_ m: Measurement) -> String { String(format: "%.1f KB", Double(m.bytes) / 1024) }
        func throttled(_ m: Measurement) -> String { String(format: "%.1f", m.throttled) }

        let table = """
            | Scenario | REST naive (sequential) | REST naive (6 concurrent) | REST batch | GraphQL (network) | GraphQL (cache) |
            |---|---|---|---|---|---|
            | Rick detail (51 episodes): requests | \(sequential.requests) | \(concurrent.requests) | \(batch.requests) | \(gqlNetwork.requests) | \(gqlCache.requests) |
            | Rick detail: total time (ms) | \(ms(sequential)) | \(ms(concurrent)) | \(ms(batch)) | \(ms(gqlNetwork)) | \(ms(gqlCache)) |
            | Rick detail: bytes (decoded body) | \(kb(sequential)) | \(kb(concurrent)) | \(kb(batch)) | \(kb(gqlNetwork)) | \(kb(gqlCache)) |
            | Rick detail: failed loads (of \(Self.runs), after retries) | \(sequential.failures) | \(concurrent.failures) | \(batch.failures) | \(gqlNetwork.failures) | \(gqlCache.failures) |
            | Rick detail: 429s per load (rate limited) | \(throttled(sequential)) | \(throttled(concurrent)) | \(throttled(batch)) | \(throttled(gqlNetwork)) | \(throttled(gqlCache)) |
            | Episode detail (cast grid): requests | n/a | n/a | \(episodeREST.requests) | \(episodeGQL.requests) | \(episodeGQLCache.requests) |
            | Episode detail: total time (ms) | n/a | n/a | \(ms(episodeREST)) | \(ms(episodeGQL)) | \(ms(episodeGQLCache)) |
            | Episode detail: bytes (decoded body) | n/a | n/a | \(kb(episodeREST)) | \(kb(episodeGQL)) | \(kb(episodeGQLCache)) |
            """
        print(table)
        if let path = ProcessInfo.processInfo.environment["BENCHMARK_OUTPUT"] {
            try (table + "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
