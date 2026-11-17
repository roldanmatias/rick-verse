import Apollo
@_spi(Unsafe) import ApolloAPI
import Foundation
import TestSupport
import Testing

@testable import DataGraphQL

struct CodegenTests {
    typealias API = RickAndMortyAPI

    private func parse<Query: GraphQLQuery>(_ query: Query, _ fixture: String) async throws -> ParsedResult<Query> {
        let response = HTTPURLResponse(
            url: URL(string: "https://rickandmortyapi.com/graphql")!, statusCode: 200,
            httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"]
        )!
        let parser = JSONResponseParser(response: response, operationVariables: query.__variables, includeCacheRecords: true)
        let parsed = try await parser.parse(
            dataChunk: try Fixture.data(fixture, in: .module),
            mergingIncrementalItemsInto: nil as ParsedResult<Query>?
        )
        return try #require(parsed)
    }

    @Test func castPageParses() async throws {
        let parsed = try await parse(API.CastPageQuery(page: 1, filter: nil), "cast_page_1")
        let characters = try #require(parsed.result.data?.characters)

        #expect(parsed.result.errors == nil)
        #expect(characters.info?.next == 2)
        #expect(characters.results?.count == 20)
        let rick = try #require(characters.results?.first??.fragments.castMemberBasic)
        #expect(rick.id == "1")
        #expect(rick.name == "Rick Sanchez")
        #expect(rick.status == "Alive")
    }

    @Test("A search with no matches is 200 with empty results (REST answered 404)")
    func noResultsIsEmpty() async throws {
        let parsed = try await parse(
            API.CastPageQuery(page: 1, filter: .some(API.FilterCharacter(name: .some("zzzzqqq")))),
            "cast_page_no_results"
        )
        #expect(parsed.result.errors == nil)
        #expect(parsed.result.data?.characters?.results?.isEmpty == true)
        #expect(parsed.result.data?.characters?.info?.next == nil)
    }

    @Test("The whole character detail, 51 episodes included, arrives in ONE response")
    func detailIsOneRequest() async throws {
        let parsed = try await parse(API.CastMemberDetailQuery(id: "1"), "cast_member_detail_1")
        let character = try #require(parsed.result.data?.character)

        #expect(character.fragments.castMemberBasic.name == "Rick Sanchez")
        #expect(character.gender == "Male")
        #expect(character.origin?.name == "Earth (C-137)")
        #expect(character.location?.name == "Citadel of Ricks")
        #expect(character.episode.count == 51)
        #expect(character.episode.first??.fragments.episodeBasic.episode == "S01E01")
        #expect(character.episode.first??.fragments.episodeBasic.air_date == "December 2, 2013")
    }

    @Test("A missing character is 200 with character: null (REST answered 404)")
    func missingCharacterIsNull() async throws {
        let parsed = try await parse(API.CastMemberDetailQuery(id: "99999"), "cast_member_detail_missing")
        #expect(parsed.result.errors == nil)
        #expect(parsed.result.data != nil)
        #expect(parsed.result.data?.character == nil)
    }

    @Test func episodePageAndDetailParse() async throws {
        let page = try await parse(API.EpisodePageQuery(page: 1), "episode_page_1")
        #expect(page.result.data?.episodes?.results?.count == 20)
        #expect(page.result.data?.episodes?.info?.next == 2)

        let detail = try await parse(API.EpisodeDetailQuery(id: "1"), "episode_detail_1")
        let episode = try #require(detail.result.data?.episode)
        #expect(episode.fragments.episodeBasic.name == "Pilot")
        #expect(episode.characters.count == 19)
    }

    @Test("Entities are normalized under Type:id keys")
    func cacheKeys() async throws {
        let parsed = try await parse(API.CastMemberDetailQuery(id: "1"), "cast_member_detail_1")
        let records = try #require(parsed.cacheRecords)
        let keys = Set(records.storage.keys)

        #expect(keys.contains("Character:1"))
        #expect(keys.contains("Episode:1"))
        #expect(keys.contains("Episode:51"))
        #expect(keys.contains("Location:1"))
        #expect(keys.contains("Location:3"))
        #expect(records["Character:1"]?["name"] as? String == "Rick Sanchez")
    }

    @Test("The same character from two different queries lands in the same record")
    func normalizationSharesRecords() async throws {
        let list = try #require(try await parse(API.CastPageQuery(page: 1, filter: nil), "cast_page_1").cacheRecords)
        let episode = try #require(try await parse(API.EpisodeDetailQuery(id: "1"), "episode_detail_1").cacheRecords)

        let shared = Set(list.storage.keys).intersection(episode.storage.keys).filter { $0.hasPrefix("Character:") }
        #expect(shared.contains("Character:1"))
        #expect(shared.contains("Character:2"))

        let store = ApolloStore(cache: InMemoryNormalizedCache())
        try await store.publish(records: list)
        try await store.publish(records: episode)
        let cachedList = try await store.withinReadTransaction { try await $0.read(query: API.CastPageQuery(page: 1, filter: nil)) }
        let cachedEpisode = try await store.withinReadTransaction { try await $0.read(query: API.EpisodeDetailQuery(id: "1")) }
        #expect(cachedList.characters?.results?.first??.fragments.castMemberBasic.name == "Rick Sanchez")
        #expect(cachedEpisode.episode?.characters.first??.fragments.castMemberBasic.name == "Rick Sanchez")
    }

    @Test("A null id falls back to a path-based key instead of colliding")
    func nullIDIsNotNormalized() async throws {
        var json = try JSONSerialization.jsonObject(with: Fixture.data("cast_page_1", in: .module)) as! [String: Any]
        var data = json["data"] as! [String: Any]
        var characters = data["characters"] as! [String: Any]
        var results = characters["results"] as! [[String: Any]]
        results[0]["id"] = NSNull()
        characters["results"] = results
        data["characters"] = characters
        json["data"] = data

        let response = HTTPURLResponse(
            url: URL(string: "https://x.y/graphql")!, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"])!
        let query = API.CastPageQuery(page: 1, filter: nil)
        let parsed = try await JSONResponseParser(response: response, operationVariables: query.__variables, includeCacheRecords: true)
            .parse(
                dataChunk: JSONSerialization.data(withJSONObject: json),
                mergingIncrementalItemsInto: nil as ParsedResult<API.CastPageQuery>?)
        let keys = Set(try #require(parsed?.cacheRecords).storage.keys)

        #expect(!keys.contains("Character:1"))
        #expect(keys.contains("Character:2"))
        #expect(keys.contains { $0.contains("results.0") })
    }
}
