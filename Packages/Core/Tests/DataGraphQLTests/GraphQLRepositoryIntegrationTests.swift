import DataGraphQL
import Domain
import Foundation
import TestSupport
import Testing

struct GraphQLRepositoryIntegrationTests {
    private func makeRepositories(_ stub: StubbedSession, policy: FetchPolicy = .networkOnly) -> GraphQLRepositories {
        DataGraphQLFactory.makeRepositories(endpoint: graphQLEndpoint, urlSession: stub.session, policy: policy)
    }

    @Test("CastPage maps to a Page, and nextPage comes straight from info.next")
    func castPage() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_1"))

        let page = try await makeRepositories(stub).cast.cast(page: 1, filter: CastFilter())

        #expect(page.items.count == 20)
        #expect(
            page.items.first
                == CastMember(
                    id: 1, name: "Rick Sanchez", status: .alive, species: "Human",
                    imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!
                ))
        #expect(page.nextPage == 2)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url == graphQLEndpoint)
        let body = try requestBody(request)
        #expect(body["operationName"] as? String == "CastPage")
        #expect((body["variables"] as? [String: Any])?["page"] as? Int == 1)
    }

    @Test("The filter is sent as typed variables, never interpolated into the query")
    func filterVariables() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_search_rick_alive"))

        _ = try await makeRepositories(stub).cast.cast(page: 1, filter: CastFilter(name: "rick", status: .alive))

        let variables = try requestBody(try #require(stub.requests.first))["variables"] as? [String: Any]
        let filter = variables?["filter"] as? [String: Any]
        #expect(filter?["name"] as? String == "rick")
        #expect(filter?["status"] as? String == "alive")
    }

    @Test("A search with no matches is an empty page (REST: 404, GraphQL: 200 + [])")
    func noResults() async throws {
        let page = try await makeRepositories(StubbedSession(try fixtureResult("cast_page_no_results")))
            .cast.cast(page: 1, filter: CastFilter(name: "zzzzqqq"))
        #expect(page.items.isEmpty)
        #expect(page.nextPage == nil)
    }

    @Test("Character detail with 51 episodes takes ONE request")
    func detailOneRequest() async throws {
        let stub = StubbedSession(try fixtureResult("cast_member_detail_1"))

        let detail = try await makeRepositories(stub).cast.detail(id: 1)

        #expect(stub.requests.count == 1)
        #expect(detail.member.name == "Rick Sanchez")
        #expect(detail.gender == "Male")
        #expect(detail.originName == "Earth (C-137)")
        #expect(detail.locationName == "Citadel of Ricks")
        #expect(detail.episodes.count == 51)
        #expect(detail.episodes.map(\.id) == Array(1...51))
        #expect(detail.episodes.first?.airDate == Date(timeIntervalSince1970: 1_385_942_400))
    }

    @Test("{\"data\": {\"character\": null}} is .notFound")
    func missingCharacter() async throws {
        let repositories = makeRepositories(StubbedSession(try fixtureResult("cast_member_detail_missing")))
        await #expect(throws: DomainError.notFound) { try await repositories.cast.detail(id: 99999) }
    }

    @Test("Partial data: data + errors returns the data, and the null item is skipped (ADR 0006)")
    func partialData() async throws {
        let stub = StubbedSession(
            try editedFixture("cast_page_1") { json in
                var data = json["data"] as! [String: Any]
                var characters = data["characters"] as! [String: Any]
                var results = characters["results"] as! [[String: Any]]
                results[1]["name"] = NSNull()
                characters["results"] = results
                data["characters"] = characters
                json["data"] = data
                json["errors"] = [["message": "Failed to resolve name", "path": ["characters", "results", 1, "name"]]]
            })

        let page = try await makeRepositories(stub).cast.cast(page: 1, filter: CastFilter())

        #expect(page.items.count == 19)
        #expect(!page.items.contains { $0.id == 2 })
        #expect(page.nextPage == 2)
    }

    @Test(arguments: ["id", "image"])
    func requiredFieldNullIsSkipped(field: String) async throws {
        let stub = StubbedSession(
            try editedFixture("cast_page_1") { json in
                var data = json["data"] as! [String: Any]
                var characters = data["characters"] as! [String: Any]
                var results = characters["results"] as! [[String: Any]]
                results[0][field] = NSNull()
                characters["results"] = results
                data["characters"] = characters
                json["data"] = data
            })
        let page = try await makeRepositories(stub).cast.cast(page: 1, filter: CastFilter())
        #expect(page.items.count == 19)
        #expect(page.items.first?.name == "Morty Smith")
    }

    @Test("Optional fields fall back instead of skipping: a null status is .unknown, a null species is \"Unknown\"")
    func optionalFieldsFallBack() async throws {
        let stub = StubbedSession(
            try editedFixture("cast_page_1") { json in
                var data = json["data"] as! [String: Any]
                var characters = data["characters"] as! [String: Any]
                var results = characters["results"] as! [[String: Any]]
                results[0]["status"] = NSNull()
                results[0]["species"] = NSNull()
                characters["results"] = results
                data["characters"] = characters
                json["data"] = data
            })
        let rick = try #require(try await makeRepositories(stub).cast.cast(page: 1, filter: CastFilter()).items.first)
        #expect(rick.status == .unknown)
        #expect(rick.species == "Unknown")
    }

    @Test("Strict for a detail's subject: a character with a null name is .invalidData")
    func detailSubjectInvalid() async throws {
        let stub = StubbedSession(
            try editedFixture("cast_member_detail_1") { json in
                var data = json["data"] as! [String: Any]
                var character = data["character"] as! [String: Any]
                character["name"] = NSNull()
                data["character"] = character
                json["data"] = data
            })
        let repositories = makeRepositories(stub)
        await #expect(throws: DomainError.invalidData) { try await repositories.cast.detail(id: 1) }
    }

    @Test("data: null with errors is .server (HTTP status was still 200)")
    func errorsOnly() async throws {
        let stub = StubbedSession(.json(#"{"data": null, "errors": [{"message": "Internal server error"}]}"#))
        let repositories = makeRepositories(stub)
        await #expect(throws: DomainError.server) { try await repositories.cast.cast(page: 1, filter: CastFilter()) }
    }

    @Test(
        "A non-2xx status with a body (Apollo's ResponseCodeError) maps to .server, and 408 maps to .timeout",
        arguments: [(500, DomainError.server), (502, .server), (503, .server), (404, .server), (408, .timeout)])
    func httpErrors(status: Int, expected: DomainError) async throws {
        let repositories = makeRepositories(StubbedSession(.json(#"{"error": "upstream failure"}"#, status: status)))
        await #expect(throws: expected) { try await repositories.cast.cast(page: 1, filter: CastFilter()) }
    }

    @Test(
        "Apollo quirk: an error status with an EMPTY body surfaces as noResults, which still maps to .server",
        arguments: [500, 503, 408])
    func httpErrorEmptyBody(status: Int) async throws {
        let repositories = makeRepositories(StubbedSession(.status(status)))
        await #expect(throws: DomainError.server) { try await repositories.cast.cast(page: 1, filter: CastFilter()) }
    }

    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, DomainError.offline),
        (.timedOut, .timeout),
    ])
    func transportErrors(code: URLError.Code, expected: DomainError) async throws {
        let repositories = makeRepositories(StubbedSession(.failure(URLError(code))))
        await #expect(throws: expected) { try await repositories.episodes.episodes(page: 1) }
    }

    @Test func episodePageAndDetail() async throws {
        let stub = StubbedSession { request in
            let name = (try? requestBody(request))?["operationName"] as? String
            return (try? fixtureResult(name == "EpisodePage" ? "episode_page_1" : "episode_detail_1")) ?? .status(500)
        }
        let repositories = makeRepositories(stub)

        let page = try await repositories.episodes.episodes(page: 1)
        #expect(page.items.count == 20)
        #expect(page.items.first?.code == "S01E01")
        #expect(page.nextPage == 2)

        let detail = try await repositories.episodes.detail(id: 1)
        #expect(detail.episode.name == "Pilot")
        #expect(detail.cast.count == 19)
        #expect(stub.requests.count == 2)
    }

    @Test("cacheFirst: the second identical query never hits the network")
    func cacheFirst() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_1"))
        let repositories = makeRepositories(stub, policy: .cacheFirst)

        _ = try await repositories.cast.cast(page: 1, filter: CastFilter())
        let second = try await repositories.cast.cast(page: 1, filter: CastFilter())

        #expect(second.items.count == 20)
        #expect(stub.requests.count == 1)
    }

    @Test("networkFirst: offline falls back to the cached response")
    func networkFirstFallsBack() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_1"), .failure(URLError(.notConnectedToInternet)))
        let repositories = makeRepositories(stub, policy: .networkFirst)

        _ = try await repositories.cast.cast(page: 1, filter: CastFilter())
        let offline = try await repositories.cast.cast(page: 1, filter: CastFilter())

        #expect(offline.items.count == 20)
        #expect(stub.requests.count == 2)
    }

    @Test("networkOnly: offline is an error even with a warm cache")
    func networkOnlyFails() async throws {
        let stub = StubbedSession(try fixtureResult("cast_page_1"), .failure(URLError(.notConnectedToInternet)))
        let repositories = makeRepositories(stub, policy: .networkOnly)

        _ = try await repositories.cast.cast(page: 1, filter: CastFilter())
        await #expect(throws: DomainError.offline) {
            try await repositories.cast.cast(page: 1, filter: CastFilter())
        }
    }
}
