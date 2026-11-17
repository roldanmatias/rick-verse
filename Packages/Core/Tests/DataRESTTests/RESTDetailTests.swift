import Domain
import Foundation
import Networking
import TestSupport
import Testing

@testable import DataREST

struct RESTCastDetailTests {
    private func rickStub() throws -> StubbedSession {
        let character = try fixture("character_1")
        let episodes = try fixture("episodes_rick")
        return StubbedSession { request in
            let path = request.url?.path() ?? ""
            if path.hasSuffix("/character/1") {
                return .response(status: 200, body: character)
            }
            if path.contains("/episode/") {
                return .response(status: 200, body: episodes)
            }
            return .status(404)
        }
    }

    @Test("Version B (batch): Rick's detail takes exactly 2 requests")
    func batchMakesTwoRequests() async throws {
        let stub = try rickStub()
        let sut = RESTCastRepository(client: makeClient(stub))

        let detail = try await sut.detail(id: 1)

        #expect(stub.requests.count == 2)
        #expect(
            stub.requests.map { $0.url?.path() ?? "" } == [
                "/api/character/1",
                "/api/episode/" + (1...51).map(String.init).joined(separator: ","),
            ])
        #expect(detail.member.name == "Rick Sanchez")
        #expect(detail.gender == "Male")
        #expect(detail.originName == "Earth (C-137)")
        #expect(detail.locationName == "Citadel of Ricks")
        #expect(detail.episodes.count == 51)
        #expect(detail.episodes.first?.code == "S01E01")
    }

    @Test("The batch endpoint sorts by ID, but the character's episode order is preserved")
    func batchPreservesCharacterOrder() async throws {
        let character = try JSONSerialization.jsonObject(with: fixture("character_1")) as! [String: Any]
        var reordered = character
        reordered["episode"] = [3, 1, 2].map { "https://rickandmortyapi.com/api/episode/\($0)" }
        let characterData = try JSONSerialization.data(withJSONObject: reordered)
        let episodes = try fixture("episodes_1_2_3")

        let stub = StubbedSession { request in
            request.url?.path().contains("/character/") == true
                ? .response(status: 200, body: characterData)
                : .response(status: 200, body: episodes)
        }
        let detail = try await RESTCastRepository(client: makeClient(stub)).detail(id: 1)

        #expect(detail.episodes.map(\.id) == [3, 1, 2])
        #expect(stub.requests.last?.url?.path() == "/api/episode/3,1,2")
    }

    @Test("A character in one episode gets a bare object back (OneOrMany)")
    func batchSingleEpisode() async throws {
        let character = try JSONSerialization.jsonObject(with: fixture("character_1")) as! [String: Any]
        var single = character
        single["episode"] = ["https://rickandmortyapi.com/api/episode/1"]
        let characterData = try JSONSerialization.data(withJSONObject: single)
        let episode = try fixture("episode_1")

        let stub = StubbedSession { request in
            request.url?.path().contains("/character/") == true
                ? .response(status: 200, body: characterData)
                : .response(status: 200, body: episode)
        }
        let detail = try await RESTCastRepository(client: makeClient(stub)).detail(id: 1)

        #expect(detail.episodes.map(\.id) == [1])
    }

    @Test func missingCharacterIsNotFound() async {
        let stub = StubbedSession(.json(#"{"error":"Character not found"}"#, status: 404))
        let sut = RESTCastRepository(client: makeClient(stub))

        await #expect(throws: DomainError.notFound) { try await sut.detail(id: 99999) }
        #expect(stub.requests.count == 1)
    }

    @Test func episodeBatchFailureMapsToDomainError() async throws {
        let character = try fixture("character_1")
        let stub = StubbedSession { request in
            request.url?.path().contains("/character/") == true
                ? .response(status: 200, body: character)
                : .status(503)
        }
        let sut = RESTCastRepository(client: makeClient(stub))
        await #expect(throws: DomainError.server) { try await sut.detail(id: 1) }
    }

    private func concurrentClient(failingEpisode: Int? = nil) throws -> FakeHTTPClient {
        let character = try fixture("character_1")
        let episodes = try JSONSerialization.jsonObject(with: fixture("episodes_rick")) as! [[String: Any]]
        let byID = try Dictionary(
            uniqueKeysWithValues: episodes.map {
                ($0["id"] as! Int, try JSONSerialization.data(withJSONObject: $0))
            })
        return FakeHTTPClient { path throws(NetworkError) in
            if path == "character/1" { return character }
            let id = Int(path.split(separator: "/").last ?? "") ?? -1
            if id == failingEpisode { throw .http(status: 500, body: Data()) }
            guard let data = byID[id] else { throw .http(status: 404, body: Data()) }
            return data
        }
    }

    @Test("Version A (concurrent): 1 + N requests, results in the original order")
    func concurrentMakesNPlusOneRequests() async throws {
        let client = try concurrentClient()
        let sut = RESTCastRepository(client: client, episodeLoading: .concurrent(maxInFlight: 6))

        let detail = try await sut.detail(id: 1)

        #expect(await client.paths.count == 52)
        #expect(detail.episodes.map(\.id) == Array(1...51))
    }

    @Test("Version A never has more than maxInFlight requests at once", arguments: [1, 3, 6])
    func concurrentRespectsLimit(maxInFlight: Int) async throws {
        let client = try concurrentClient()
        let sut = RESTCastRepository(client: client, episodeLoading: .concurrent(maxInFlight: maxInFlight))

        _ = try await sut.detail(id: 1)

        let peak = await client.peakInFlight
        #expect(peak <= maxInFlight)
        #expect(peak == maxInFlight, "requests should actually overlap up to the limit")
    }

    @Test("Version A: one failed episode fails the whole detail")
    func concurrentFailure() async throws {
        let sut = RESTCastRepository(
            client: try concurrentClient(failingEpisode: 7),
            episodeLoading: .concurrent(maxInFlight: 6))
        await #expect(throws: DomainError.server) { try await sut.detail(id: 1) }
    }

    @Test(arguments: [RESTCastRepository.EpisodeLoading.batch, .concurrent(maxInFlight: 6)])
    func noEpisodesMeansOneRequest(loading: RESTCastRepository.EpisodeLoading) async throws {
        let character = try JSONSerialization.jsonObject(with: fixture("character_1")) as! [String: Any]
        var none = character
        none["episode"] = [String]()
        let data = try JSONSerialization.data(withJSONObject: none)
        let client = FakeHTTPClient { _ in data }

        let detail = try await RESTCastRepository(client: client, episodeLoading: loading).detail(id: 1)

        #expect(detail.episodes.isEmpty)
        #expect(await client.paths == ["character/1"])
    }
}

struct RESTEpisodeDetailTests {
    @Test("Episode detail: the episode plus a batch of its cast, 2 requests, cast in the episode's order")
    func episodeDetail() async throws {
        let episode = try fixture("episode_1")
        let characters = try fixture("characters_episode_1")
        let stub = StubbedSession { request in
            request.url?.path().contains("/episode/") == true
                ? .response(status: 200, body: episode)
                : .response(status: 200, body: characters)
        }

        let detail = try await RESTEpisodeRepository(client: makeClient(stub)).detail(id: 1)

        #expect(stub.requests.count == 2)
        #expect(
            stub.requests.last?.url?.path()
                == "/api/character/1,2,35,38,62,92,127,144,158,175,179,181,239,249,271,338,394,395,435")
        #expect(detail.episode.name == "Pilot")
        #expect(detail.cast.count == 19)
        #expect(detail.cast.prefix(2).map(\.name) == ["Rick Sanchez", "Morty Smith"])
    }

    @Test func singleCharacterBatchIsAnObject() async throws {
        let episode = try JSONSerialization.jsonObject(with: fixture("episode_1")) as! [String: Any]
        var single = episode
        single["characters"] = ["https://rickandmortyapi.com/api/character/1"]
        let episodeData = try JSONSerialization.data(withJSONObject: single)
        let rick = try fixture("character_1")

        let stub = StubbedSession { request in
            request.url?.path().contains("/episode/") == true
                ? .response(status: 200, body: episodeData)
                : .response(status: 200, body: rick)
        }
        let detail = try await RESTEpisodeRepository(client: makeClient(stub)).detail(id: 1)

        #expect(detail.cast.map(\.id) == [1])
    }

    @Test func missingEpisodeIsNotFound() async {
        let sut = RESTEpisodeRepository(client: makeClient(StubbedSession(.json(#"{"error":"Episode not found"}"#, status: 404))))
        await #expect(throws: DomainError.notFound) { try await sut.detail(id: 999) }
    }
}

struct OrderedByIDsTests {
    @Test func reordersAndSkipsMissing() {
        #expect([1, 2, 3, 5].ordered(by: [5, 4, 1], id: { $0 }) == [5, 1])
    }
}
