import Domain
import Foundation
import Networking
import Testing

@testable import DataREST

@Suite(.enabled(if: contractTestsEnabled))
struct RESTContractTests {
    let client = URLSessionHTTPClient(baseURL: restBase)

    @Test("GET /character?page=1 decodes into PageDTO<CharacterDTO>, and info.next is a URL")
    func characterPage() async throws {
        let page = try await client.send(CharacterEndpoints.list(page: 1, filter: CastFilter()))
        #expect(page.results.count == 20)
        let next = try #require(page.info.next)
        #expect(next.scheme == "https")
        #expect(next.pageQueryItem == 2)
    }

    @Test("A search with no results is still 404 with an `error` body (not an empty list)")
    func noResultsIs404() async throws {
        do {
            _ = try await client.send(CharacterEndpoints.list(page: 1, filter: CastFilter(name: "zzzzqqq-contract")))
            Issue.record("Expected a 404")
        } catch {
            guard case let .http(status, body) = error else {
                Issue.record("Expected .http, got \(error)")
                return
            }
            #expect(status == 404)
            #expect(APIError.isAPIError(body))
        }

        let page = try await RESTCastRepository(client: client).cast(page: 1, filter: CastFilter(name: "zzzzqqq-contract"))
        #expect(page.items.isEmpty)
    }

    @Test("GET /episode/1 is an object, GET /episode/1,2 is an array (OneOrMany)")
    func oneOrManyShapes() async throws {
        let single = try await rawGET("episode/1")
        let many = try await rawGET("episode/1,2")
        #expect(single.json is [String: Any])
        #expect((many.json as? [Any])?.count == 2)

        #expect(try await client.send(EpisodeEndpoints.byIDs([1])).values.map(\.id) == [1])
        #expect(try await client.send(EpisodeEndpoints.byIDs([1, 2])).values.map(\.id) == [1, 2])
    }

    @Test("The batch endpoint sorts by ID, whatever order is requested (we reorder)")
    func batchSortsByID() async throws {
        let batch = try await client.send(EpisodeEndpoints.byIDs([5, 1, 3])).values
        #expect(batch.map(\.id) == [1, 3, 5])
    }

    @Test("status values are still Alive / Dead / unknown")
    func statusValues() async throws {
        let page = try await client.send(CharacterEndpoints.list(page: 1, filter: CastFilter()))
        #expect(Set(page.results.map(\.status)).isSubset(of: ["Alive", "Dead", "unknown"]))
    }

    @Test("air_date is still \"Month d, yyyy\", and episode codes are still SxxEyy")
    func episodeFormats() async throws {
        let page = try await client.send(EpisodeEndpoints.list(page: 1))
        for episode in page.results {
            #expect(AirDate.parse(episode.airDate) != nil, "unparseable air_date: \(episode.airDate)")
            #expect(EpisodeCode.parse(episode.code) != nil, "unparseable code: \(episode.code)")
        }
    }

    @Test("created dates have fractional seconds (the reason for the custom date strategy)")
    func fractionalSecondDates() async throws {
        let (_, json) = try await rawGET("character/1")
        let created = try #require((json as? [String: Any])?["created"] as? String)
        #expect(created.contains("."))
        _ = try await client.send(CharacterEndpoints.byID(1))
    }

    @Test("Rick's detail still takes 2 requests with the batch strategy")
    func detailEndToEnd() async throws {
        let log = NetworkLog()
        let client = URLSessionHTTPClient(baseURL: restBase, middlewares: [MetricsMiddleware(log: log)])
        let detail = try await RESTCastRepository(client: client).detail(id: 1)
        #expect(detail.member.name == "Rick Sanchez")
        #expect(detail.episodes.count >= 51)
        #expect(await log.events.count == 2)
    }
}
