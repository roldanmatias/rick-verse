import Foundation
import Testing

@testable import RickVerse

struct RouteDeepLinkTests {
    @Test(arguments: [
        ("rickverse://character/1", Route.castMember(id: 1)),
        ("rickverse://character/826", .castMember(id: 826)),
        ("rickverse://episode/28", .episode(id: 28)),
        ("RICKVERSE://Episode/3", .episode(id: 3)),
    ])
    func parses(url: String, expected: Route) throws {
        #expect(Route(url: try #require(URL(string: url))) == expected)
    }

    @Test(arguments: [
        "https://character/1",
        "rickverse://location/1",
        "rickverse://character",
        "rickverse://character/abc",
        "rickverse://character/0",
        "rickverse://character/1/extra",
    ])
    func rejects(url: String) throws {
        #expect(Route(url: try #require(URL(string: url))) == nil)
    }

    @Test(arguments: [Route.castMember(id: 1), .episode(id: 51)])
    func roundTrips(route: Route) {
        #expect(Route(url: route.url) == route)
    }
}
