import DataREST
import Domain
import Foundation
import TestSupport
import Testing

struct RESTEpisodeRepositoryTests {
    @Test func mapsFirstPage() async throws {
        let stub = StubbedSession(try fixtureResult("episodes_page1"))
        let sut = RESTEpisodeRepository(client: makeClient(stub))

        let page = try await sut.episodes(page: 1)

        #expect(page.items.count == 20)
        #expect(page.items.first?.code == "S01E01")
        #expect(page.nextPage == 2)
        #expect(stub.requests.first?.url?.absoluteString == "https://rickandmortyapi.com/api/episode?page=1")
    }

    @Test func malformedEpisodeCodeMapsToInvalidData() async {
        let json = #"""
            {"info": {"count": 1, "pages": 1, "next": null, "prev": null},
             "results": [{"id": 1, "name": "x", "air_date": "", "episode": "Pilot", "characters": [],
                          "url": "https://x.y/episode/1", "created": "2017-11-10T12:56:33.798Z"}]}
            """#
        let sut = RESTEpisodeRepository(client: makeClient(StubbedSession(.json(json))))
        await #expect(throws: DomainError.invalidData) { try await sut.episodes(page: 1) }
    }

    @Test func serverErrorMapsToServer() async {
        let sut = RESTEpisodeRepository(client: makeClient(StubbedSession(.status(503))))
        await #expect(throws: DomainError.server) { try await sut.episodes(page: 1) }
    }
}
