import Domain
import Foundation
import Testing

@testable import DataREST

struct EpisodeMapperTests {
    @Test("episode_1.json maps to the Pilot")
    func mapsRealFixture() throws {
        let episode = try decodeFixture(EpisodeDTO.self, "episode_1").toDomain()

        #expect(episode.id == 1)
        #expect(episode.name == "Pilot")
        #expect(episode.code == "S01E01")
        #expect(episode.season == 1)
        #expect(episode.number == 1)
        #expect(episode.airDate == Date(timeIntervalSince1970: 1_385_942_400))
    }

    @Test(arguments: [
        ("S01E01", 1, 1), ("S02E10", 2, 10), ("S05E10", 5, 10), ("S10E100", 10, 100),
    ])
    func parsesCode(code: String, season: Int, number: Int) throws {
        let parsed = try #require(EpisodeCode.parse(code))
        #expect(parsed.season == season)
        #expect(parsed.number == number)
    }

    @Test(arguments: ["", "Pilot", "S01", "E01", "s01e01", "S01E01 ", "SxxE01"])
    func rejectsMalformedCode(code: String) {
        #expect(EpisodeCode.parse(code) == nil)
    }

    @Test func malformedCodeThrowsInvalidData() throws {
        let json = #"""
            {"id": 1, "name": "x", "air_date": "", "episode": "Pilot", "characters": [],
             "url": "https://x.y/episode/1", "created": "2017-11-10T12:56:33.798Z"}
            """#
        let dto = try JSONDecoder.rickVerse.decode(EpisodeDTO.self, from: Data(json.utf8))
        #expect(throws: DomainError.invalidData) { try dto.toDomain() }
    }

    @Test(arguments: [
        ("December 2, 2013", 1_385_942_400.0),
        ("September 10, 2017", 1_505_001_600.0),
        ("May 3, 2020", 1_588_464_000.0),
    ])
    func parsesAirDate(string: String, epoch: Double) {
        #expect(AirDate.parse(string) == Date(timeIntervalSince1970: epoch))
    }

    @Test(arguments: ["", "2013-12-02", "diciembre 2, 2013"])
    func unparseableAirDateIsNil(string: String) {
        #expect(AirDate.parse(string) == nil)
    }

    @Test("Why the locale is pinned: a Spanish formatter can't read the API's dates")
    func spanishLocaleWouldFail() {
        let spanish = Date.ParseStrategy(
            format: "\(month: .wide) \(day: .defaultDigits), \(year: .defaultDigits)",
            locale: Locale(identifier: "es_ES"), timeZone: .gmt
        )
        #expect((try? Date("December 2, 2013", strategy: spanish)) == nil)
        #expect(AirDate.parse("December 2, 2013") != nil)
    }

    @Test func episodesPageMaps() throws {
        let page = try decodeFixture(PageDTO<EpisodeDTO>.self, "episodes_page1")
            .toDomain { dto throws(DomainError) in try dto.toDomain() }
        #expect(page.items.count == 20)
        #expect(page.items.map(\.id) == Array(1...20))
        #expect(page.nextPage == 2)
        #expect(page.items.allSatisfy { $0.airDate != nil })
    }
}
