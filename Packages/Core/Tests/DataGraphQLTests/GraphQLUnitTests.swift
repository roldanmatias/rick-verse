import Apollo
@_spi(Unsafe) import ApolloAPI
import Domain
import Foundation
import Testing

@testable import DataGraphQL

struct GraphQLUnitTests {
    typealias API = RickAndMortyAPI

    struct FakeClient: GraphQLClient {
        var fixtureName: String?
        var error: (any Error)?

        func fetch<Query: GraphQLQuery>(_ query: Query, policy: FetchPolicy) async throws -> Query.Data
        where Query.ResponseFormat == SingleResponseFormat {
            if let error { throw error }
            let json = try JSONSerialization.jsonObject(with: fixture(try #require(fixtureName))) as! [String: Any]
            return try await Query.Data(data: json["data"] as! [String: Any], variables: query.__variables)
        }
    }

    @Test func repositoryMapsFixtureData() async throws {
        let sut = GraphQLCastRepository(client: FakeClient(fixtureName: "cast_member_detail_1"), policy: .cacheFirst)
        let detail = try await sut.detail(id: 1)
        #expect(detail.episodes.count == 51)
        #expect(detail.member.status == .alive)
    }

    @Test(arguments: [
        (CastFilter(), false, nil as String?, nil as String?),
        (CastFilter(name: "rick"), true, "rick", nil),
        (CastFilter(status: .dead), true, nil, "dead"),
        (CastFilter(name: "rick", status: .alive), true, "rick", "alive"),
    ])
    func filterInput(filter: CastFilter, sent: Bool, name: String?, status: String?) throws {
        let input = GraphQLCastRepository.filterInput(filter)
        guard case let .some(value) = input else {
            #expect(!sent)
            return
        }
        #expect(sent)
        #expect(value.name.unwrapped == name)
        #expect(value.status.unwrapped == status)
    }

    @Test(
        arguments: [
            (URLError(.notConnectedToInternet) as any Error, DomainError.offline),
            (URLError(.networkConnectionLost), .offline),
            (URLError(.timedOut), .timeout),
            (URLError(.cancelled), .cancelled),
            (CancellationError(), .cancelled),
            (GraphQLClientError.noData(errors: ["boom"]), .server),
            (GraphQLClientError.transport(URLError(.notConnectedToInternet)), .offline),
            (DomainError.notFound, .notFound),
            (NSError(domain: "x", code: 1), .unknown),
        ] as [(any Error, DomainError)])
    func errorMapping(error: any Error, expected: DomainError) {
        #expect(GraphQLErrorMapper.map(error) == expected)
    }

    @Test("The protocol's default fetchUpdates yields fetch's value exactly once")
    func defaultFetchUpdatesYieldsOnce() async throws {
        let client = FakeClient(fixtureName: "cast_member_detail_1")
        var names: [String?] = []
        for try await data in client.fetchUpdates(API.CastMemberDetailQuery(id: "1"), policy: .cacheAndNetwork) {
            names.append(data.character?.fragments.castMemberBasic.name)
        }
        #expect(names == ["Rick Sanchez"])
    }

    @Test func defaultFetchUpdatesFinishesWithTheError() async {
        let client = FakeClient(error: URLError(.notConnectedToInternet))
        await #expect(throws: URLError(.notConnectedToInternet)) {
            for try await _ in client.fetchUpdates(API.CastPageQuery(page: 1, filter: nil), policy: .cacheFirst) {}
        }
    }

    @Test func fakeClientErrorsAreMapped() async {
        let sut = GraphQLEpisodeRepository(client: FakeClient(error: URLError(.timedOut)), policy: .cacheFirst)
        await #expect(throws: DomainError.timeout) { try await sut.episodes(page: 1) }
    }

    @Test(arguments: [("Alive", CastMember.Status.alive), ("Dead", .dead), ("unknown", .unknown), ("Zombie", .unknown)])
    func status(raw: String, expected: CastMember.Status) {
        #expect(CastMember.Status(apiValue: raw) == expected)
    }

    @Test func nilStatusIsUnknown() {
        #expect(CastMember.Status(apiValue: nil) == .unknown)
    }

    @Test func episodeCodeAndAirDate() {
        #expect(EpisodeCode.parse("S02E10")?.season == 2)
        #expect(EpisodeCode.parse("S02E10")?.number == 10)
        #expect(EpisodeCode.parse("Pilot") == nil)
        #expect(AirDate.parse("December 2, 2013") == Date(timeIntervalSince1970: 1_385_942_400))
        #expect(AirDate.parse("2013-12-02") == nil)
        #expect(AirDate.parse(nil) == nil)
    }
}

private extension GraphQLNullable {
    var unwrapped: Wrapped? {
        if case let .some(value) = self { value } else { nil }
    }
}
