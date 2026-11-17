import DataREST
import Domain
import Foundation
import Networking
import TestSupport
import Testing

struct RESTCastRepositoryTests {
    @Test func mapsFirstPage() async throws {
        let stub = StubbedSession(try fixtureResult("characters_page1"))
        let sut = RESTCastRepository(client: makeClient(stub))

        let page = try await sut.cast(page: 1, filter: CastFilter())

        #expect(page.items.count == 20)
        #expect(page.items.first?.name == "Rick Sanchez")
        #expect(page.nextPage == 2)
        #expect(stub.requests.first?.url?.absoluteString == "https://rickandmortyapi.com/api/character?page=1")
    }

    @Test func sendsFilterAsQueryItems() async throws {
        let stub = StubbedSession(try fixtureResult("characters_page1"))
        let sut = RESTCastRepository(client: makeClient(stub))

        _ = try await sut.cast(page: 2, filter: CastFilter(name: "Rick Sanchez", status: .alive))

        #expect(
            stub.requests.first?.url?.absoluteString
                == "https://rickandmortyapi.com/api/character?page=2&name=Rick%20Sanchez&status=alive")
    }

    @Test func lastPageHasNoNextPage() async throws {
        let sut = RESTCastRepository(client: makeClient(StubbedSession(try fixtureResult("characters_last_page"))))
        let page = try await sut.cast(page: 42, filter: CastFilter())
        #expect(page.nextPage == nil)
    }

    @Test("A search with no matches (404 \"There is nothing here\") is an empty page, not .notFound")
    func noResultsIsEmptyPage() async throws {
        let stub = StubbedSession(try fixtureResult("search_no_results_404", status: 404))
        let sut = RESTCastRepository(client: makeClient(stub))

        let page = try await sut.cast(page: 1, filter: CastFilter(name: "zzzzqqq"))

        #expect(page.items.isEmpty)
        #expect(!page.hasMore)
    }

    @Test("A 404 that isn't the API's JSON (for example a wrong base URL) is still .notFound")
    func foreign404IsNotFound() async {
        let stub = StubbedSession(.response(status: 404, headers: ["Content-Type": "text/html"], body: Data("<h1>Not Found</h1>".utf8)))
        let sut = RESTCastRepository(client: makeClient(stub))
        await #expect(throws: DomainError.notFound) { try await sut.cast(page: 1, filter: CastFilter()) }
    }

    @Test func serverErrorMapsToServer() async {
        let sut = RESTCastRepository(client: makeClient(StubbedSession(.status(500))))
        await #expect(throws: DomainError.server) { try await sut.cast(page: 1, filter: CastFilter()) }
    }

    @Test func offlineMapsToOffline() async {
        let sut = RESTCastRepository(client: makeClient(StubbedSession(.failure(URLError(.notConnectedToInternet)))))
        await #expect(throws: DomainError.offline) { try await sut.cast(page: 1, filter: CastFilter()) }
    }

    @Test func malformedJSONMapsToInvalidData() async {
        let sut = RESTCastRepository(client: makeClient(StubbedSession(.json(#"{"info": {}, "results": []}"#))))
        await #expect(throws: DomainError.invalidData) { try await sut.cast(page: 1, filter: CastFilter()) }
    }
}
