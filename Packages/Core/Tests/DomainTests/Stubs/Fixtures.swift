import Domain
import Foundation

extension CastMember {
    static func fixture(id: Int = 1, name: String = "Rick Sanchez", status: Status = .alive) -> CastMember {
        CastMember(
            id: id,
            name: name,
            status: status,
            species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg")!
        )
    }
}

extension Episode {
    static func fixture(id: Int = 1) -> Episode {
        Episode(id: id, name: "Pilot", code: "S01E01", season: 1, number: 1, airDate: nil)
    }
}
