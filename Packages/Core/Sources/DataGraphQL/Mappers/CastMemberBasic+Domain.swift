import Domain
import Foundation
import os

extension RickAndMortyAPI.CastMemberBasic {
    func toDomain() -> CastMember? {
        guard let id = id.flatMap({ Int($0) }),
            let name, !name.isEmpty,
            let image, let imageURL = URL(string: image)
        else {
            MappingLog.skipped("Character", id: id)
            return nil
        }
        return CastMember(
            id: id,
            name: name,
            status: CastMember.Status(apiValue: status),
            species: species ?? "Unknown",
            imageURL: imageURL
        )
    }
}

enum MappingLog {
    private static let logger = Logger(subsystem: "RickVerse", category: "GraphQLMapping")

    static func skipped(_ type: String, id: String?) {
        logger.warning("Skipped \(type, privacy: .public) with id \(id ?? "nil", privacy: .public): a required field is null or invalid")
    }
}
