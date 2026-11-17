import Domain
import Presentation
import Testing

struct SeasonSectionTests {
    @Test("Groups by season ascending, and episodes by number, whatever the input order")
    func groups() {
        let episodes: [Episode] = [
            .fixture(season: 2, number: 1), .fixture(season: 1, number: 2),
            .fixture(season: 3, number: 1), .fixture(season: 1, number: 1),
            .fixture(season: 2, number: 10), .fixture(season: 2, number: 2),
        ]

        let sections = SeasonSection.group(episodes)

        #expect(sections.map(\.season) == [1, 2, 3])
        #expect(sections[0].episodes.map(\.number) == [1, 2])
        #expect(sections[1].episodes.map(\.number) == [1, 2, 10])
    }

    @Test func emptyInputIsNoSections() {
        #expect(SeasonSection.group([]).isEmpty)
    }
}
