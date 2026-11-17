import DataGraphQL
import Domain
import Foundation
import Networking
import Testing

@Suite(.enabled(if: contractTestsEnabled))
struct GraphQLContractTests {
    @Test("CastPage returns non-empty results, with info.next as an Int")
    func castPage() async throws {
        let json = try await rawGraphQL("{ characters(page: 1) { info { next } results { id name } } }")
        let characters = try #require((json["data"] as? [String: Any])?["characters"] as? [String: Any])
        #expect(((characters["results"] as? [Any])?.count ?? 0) > 0)
        #expect((characters["info"] as? [String: Any])?["next"] is NSNumber)

        let page = try await DataGraphQLFactory.makeRepositories(policy: .networkOnly).cast.cast(page: 1, filter: CastFilter())
        #expect(page.items.count == 20)
        #expect(page.nextPage == 2)
    }

    @Test("A search with no matches is 200 with empty results (unlike REST's 404)")
    func noResultsIsEmpty() async throws {
        let page = try await DataGraphQLFactory.makeRepositories(policy: .networkOnly)
            .cast.cast(page: 1, filter: CastFilter(name: "zzzzqqq-contract"))
        #expect(page.items.isEmpty)
    }

    @Test("A missing character is data.character = null, which maps to .notFound")
    func missingCharacter() async throws {
        let json = try await rawGraphQL("{ character(id: 99999) { id } }")
        #expect((json["data"] as? [String: Any])?["character"] is NSNull)
        await #expect(throws: DomainError.notFound) {
            try await DataGraphQLFactory.makeRepositories(policy: .networkOnly).cast.detail(id: 99999)
        }
    }

    @Test("Rick's detail takes ONE request")
    func detailOneRequest() async throws {
        let log = NetworkLog()
        let detail = try await GraphQLDataSource(log: log).repositories(policy: .networkOnly).cast.detail(id: 1)
        #expect(detail.episodes.count >= 51)
        #expect(await log.events.count == 1)
    }
}
