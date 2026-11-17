import Domain

extension CharacterDTO {
    var episodeIDs: [Int] { episode.compactMap(\.trailingID) }

    func toDetail(episodes: [Episode]) -> CastMemberDetail {
        CastMemberDetail(
            member: toDomain(),
            gender: gender,
            originName: origin.name,
            locationName: location.name,
            episodes: episodes
        )
    }
}

extension EpisodeDTO {
    var characterIDs: [Int] { characters.compactMap(\.trailingID) }
}
