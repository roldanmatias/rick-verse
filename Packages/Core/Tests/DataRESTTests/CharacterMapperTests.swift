import Domain
import Foundation
import Testing

@testable import DataREST

struct CharacterMapperTests {
    @Test("character_1.json maps to Rick")
    func mapsRealFixture() throws {
        let dto = try decodeFixture(CharacterDTO.self, "character_1")

        #expect(
            dto.toDomain()
                == CastMember(
                    id: 1, name: "Rick Sanchez", status: .alive, species: "Human",
                    imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!
                ))
        #expect(dto.origin.name == "Earth (C-137)")
        #expect(dto.location.name == "Citadel of Ricks")
        #expect(dto.episode.count == 51)
        #expect(dto.episode.first?.trailingID == 1)
        #expect(dto.created.timeIntervalSince1970 == 1_509_821_326.25)
    }

    @Test("An empty origin URL doesn't break decoding (Morty's origin is {name: unknown, url: \"\"})")
    func emptyLocationURL() throws {
        let page = try decodeFixture(PageDTO<CharacterDTO>.self, "characters_page1")
        let morty = try #require(page.results.first { $0.id == 2 })
        #expect(morty.origin.name == "unknown")
        #expect(morty.origin.url == "")
    }

    @Test(arguments: [
        ("Alive", CastMember.Status.alive), ("alive", .alive), ("ALIVE", .alive),
        ("Dead", .dead), ("unknown", .unknown),
        ("Zombie", .unknown), ("", .unknown),
    ])
    func statusMapping(raw: String, expected: CastMember.Status) {
        #expect(CastMember.Status(apiValue: raw) == expected)
    }

    @Test func pageMapsResultsAndNextPage() throws {
        let page = try decodeFixture(PageDTO<CharacterDTO>.self, "characters_page1").toDomain { $0.toDomain() }
        #expect(page.items.count == 20)
        #expect(page.items.first?.name == "Rick Sanchez")
        #expect(page.nextPage == 2)
        #expect(page.hasMore)
    }

    @Test func lastPageHasNoNextPage() throws {
        let page = try decodeFixture(PageDTO<CharacterDTO>.self, "characters_last_page").toDomain { $0.toDomain() }
        #expect(!page.items.isEmpty)
        #expect(page.nextPage == nil)
        #expect(!page.hasMore)
    }
}
