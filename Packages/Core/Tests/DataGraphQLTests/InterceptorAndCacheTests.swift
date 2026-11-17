import DataGraphQL
import Domain
import Foundation
import Networking
import TestSupport
import Testing

struct InterceptorAndCacheTests {
    @Test("Each network round trip is logged with the operation name, the status and the bytes")
    func metricsRecordsRoundTrip() async throws {
        let log = NetworkLog()
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))
        let repositories = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session, log: log)
            .repositories(policy: .networkOnly)

        _ = try await repositories.cast.detail(id: 1)

        let event = try #require(await log.events.first)
        #expect(await log.events.count == 1)
        #expect(event.source == .graphQL)
        #expect(event.label == "CastMemberDetail")
        #expect(event.status == 200)
        #expect(event.bytes == (try fixture("cast_member_detail_1")).count)
    }

    @Test("8.3 demo: with cacheFirst, opening the same character again makes ZERO requests")
    func cacheFirstSecondOpenIsFree() async throws {
        let log = NetworkLog()
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))
        let cast = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session, log: log)
            .repositories(policy: .cacheFirst).cast

        _ = try await cast.detail(id: 1)
        _ = try await cast.detail(id: 1)

        #expect(stub.requests.count == 1)
        #expect(await log.events.count == 1, "cache hits never reach the HTTP interceptors")
    }

    @Test("Clearing the cache makes the next cacheFirst read go to the network")
    func clearCache() async throws {
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))
        let source = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session)
        let cast = source.repositories(policy: .cacheFirst).cast

        _ = try await cast.detail(id: 1)
        try await source.clearCache()
        _ = try await cast.detail(id: 1)

        #expect(stub.requests.count == 2)
    }

    @Test("Repositories for different policies share one normalized cache")
    func policiesShareTheCache() async throws {
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))
        let source = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session)

        _ = try await source.repositories(policy: .networkOnly).cast.detail(id: 1)
        _ = try await source.repositories(policy: .cacheFirst).cast.detail(id: 1)

        #expect(stub.requests.count == 1)
    }

    @Test func failedRequestIsLoggedWithoutStatus() async throws {
        let log = NetworkLog()
        let stub = StubbedSession(.failure(URLError(.notConnectedToInternet)))
        let cast = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session, log: log)
            .repositories(policy: .networkOnly).cast

        await #expect(throws: DomainError.offline) { try await cast.detail(id: 1) }

        let event = try #require(await log.events.first)
        #expect(event.status == nil)
        #expect(event.label == "CastMemberDetail")
    }

    @Test func clientHeaderIsSent() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_1"))
        _ = try await DataGraphQLFactory.makeRepositories(endpoint: graphQLEndpoint, urlSession: stub.session)
            .cast.cast(page: 1, filter: CastFilter())
        #expect(stub.requests.first?.value(forHTTPHeaderField: "X-Client") == "RickVerse-iOS")
    }

    private func detailResult(name: String) throws -> StubResult {
        try editedFixture("cast_member_detail_1") { json in
            var data = json["data"] as! [String: Any]
            var character = data["character"] as! [String: Any]
            character["name"] = name
            data["character"] = character
            json["data"] = data
        }
    }

    @Test("cacheAndNetwork: a cold cache yields once (network), a warm cache yields cached then fresh")
    func staleWhileRevalidate() async throws {
        let stub = StubbedSession(try detailResult(name: "Rick (v1)"), try detailResult(name: "Rick (v2)"))
        let cast = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session)
            .repositories(policy: .cacheAndNetwork).cast

        var cold: [String] = []
        for try await detail in cast.detailUpdates(id: 1) { cold.append(detail.member.name) }
        #expect(cold == ["Rick (v1)"])

        var warm: [String] = []
        for try await detail in cast.detailUpdates(id: 1) { warm.append(detail.member.name) }
        #expect(warm == ["Rick (v1)", "Rick (v2)"])
        #expect(stub.requests.count == 2)
    }

    @Test("Other policies yield exactly once")
    func otherPoliciesYieldOnce() async throws {
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))
        let cast = GraphQLDataSource(endpoint: graphQLEndpoint, urlSession: stub.session)
            .repositories(policy: .cacheFirst).cast

        _ = try await cast.detail(id: 1)
        var count = 0
        for try await _ in cast.detailUpdates(id: 1) { count += 1 }

        #expect(count == 1)
        #expect(stub.requests.count == 1)
    }

    @Test("Stream errors are DomainErrors")
    func streamErrorsAreMapped() async throws {
        let cast = GraphQLDataSource(
            endpoint: graphQLEndpoint, urlSession: StubbedSession(try fixtureResult("cast_member_detail_missing")).session
        )
        .repositories(policy: .cacheAndNetwork).cast
        await #expect(throws: DomainError.notFound) {
            for try await _ in cast.detailUpdates(id: 99999) {}
        }
    }
}
