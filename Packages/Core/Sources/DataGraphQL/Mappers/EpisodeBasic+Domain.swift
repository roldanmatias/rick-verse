import Domain

extension RickAndMortyAPI.EpisodeBasic {
    func toDomain() -> Episode? {
        guard let id = id.flatMap({ Int($0) }),
            let name,
            let code = episode, let (season, number) = EpisodeCode.parse(code)
        else {
            MappingLog.skipped("Episode", id: id)
            return nil
        }
        return Episode(
            id: id, name: name, code: code, season: season, number: number,
            airDate: AirDate.parse(air_date))
    }
}
