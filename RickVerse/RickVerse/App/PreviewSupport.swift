import Domain
import Foundation
import Presentation

nonisolated struct PreviewCastRepository: CastRepository {
    var delay: Duration = .milliseconds(600)
    var result: Result<Page<CastMember>, DomainError>?
    var detailResult: Result<CastMemberDetail, DomainError>?
    var failure: DomainError?

    var isEmpty = false

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        try? await Task.sleep(for: delay)
        if let failure { throw failure }
        if let result { return try result.get() }
        if isEmpty { return Page(items: [], nextPage: nil) }
        let items = CastMember.samples.filter { member in
            (filter.name.map { member.name.localizedCaseInsensitiveContains($0) } ?? true)
                && (filter.status.map { member.status == $0 } ?? true)
        }
        return Page(items: items, nextPage: nil)
    }

    func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        try? await Task.sleep(for: delay)
        if let failure { throw failure }
        if let detailResult { return try detailResult.get() }
        guard let member = CastMember.samples.first(where: { $0.id == id }) else { throw .notFound }
        return CastMemberDetail(
            member: member, gender: "Male", originName: "Earth (C-137)",
            locationName: "Citadel of Ricks", episodes: isEmpty ? [] : Episode.samples)
    }
}

nonisolated struct PreviewEpisodeRepository: EpisodeRepository {
    var delay: Duration = .milliseconds(600)
    var result: Result<Page<Episode>, DomainError>?
    var detailResult: Result<EpisodeDetail, DomainError>?
    var failure: DomainError?

    var isEmpty = false

    func episodes(page: Int) async throws(DomainError) -> Page<Episode> {
        try? await Task.sleep(for: delay)
        if let failure { throw failure }
        return try result?.get() ?? Page(items: isEmpty ? [] : Episode.samples, nextPage: nil)
    }

    func detail(id: Int) async throws(DomainError) -> EpisodeDetail {
        try? await Task.sleep(for: delay)
        if let failure { throw failure }
        if let detailResult { return try detailResult.get() }
        guard let episode = Episode.samples.first(where: { $0.id == id }) else { throw .notFound }
        return EpisodeDetail(episode: episode, cast: isEmpty ? [] : CastMember.samples)
    }
}

extension ViewModelFactory {
    static func preview(
        cast: PreviewCastRepository = PreviewCastRepository(),
        episodes: PreviewEpisodeRepository = PreviewEpisodeRepository()
    ) -> ViewModelFactory {
        ViewModelFactory(
            makeCastList: { CastListViewModel(searchCast: SearchCastUseCase(repository: cast)) },
            makeCastDetail: { CastDetailViewModel(id: $0, getDetail: GetCastMemberDetailUseCase(repository: cast)) },
            makeEpisodeList: { EpisodeListViewModel(getEpisodes: GetEpisodesUseCase(repository: episodes)) },
            makeEpisodeDetail: { EpisodeDetailViewModel(id: $0, getDetail: GetEpisodeDetailUseCase(repository: episodes)) },
            makeNetworkLog: {
                NetworkLogViewModel(
                    updates: { AsyncStream { $0.yield(NetworkLogEntry.samples) } },
                    clear: {}
                )
            }
        )
    }
}

nonisolated extension CastMember {
    private static let avatarBase = URL(string: "https://rickandmortyapi.com/api/character/avatar")!
    private static let blankImage = URL(string: "about:blank")!

    static let samples: [CastMember] = [
        (1, "Rick Sanchez", Status.alive, "Human"),
        (2, "Morty Smith", .alive, "Human"),
        (3, "Summer Smith", .alive, "Human"),
        (8, "Adjudicator Rick", .dead, "Human"),
        (6, "Abadango Cluster Princess", .alive, "Alien"),
        (16, "Amish Cyborg", .dead, "Alien"),
        (15, "Alien Rick", .unknown, "Alien"),
    ].map { id, name, status, species in
        CastMember(
            id: id, name: name, status: status, species: species,
            imageURL: avatarBase.appending(path: "\(id).jpeg")
        )
    }

    static func placeholder(_ id: Int) -> CastMember {
        CastMember(
            id: -id, name: "Placeholder name", status: .unknown, species: "Species",
            imageURL: blankImage
        )
    }
}

nonisolated extension Episode {
    static let samples: [Episode] = [
        (1, "Pilot", 1, 1, 1_385_942_400.0),
        (2, "Lawnmower Dog", 1, 2, 1_386_547_200),
        (3, "Anatomy Park", 1, 3, 1_387_152_000),
        (12, "A Rickle in Time", 2, 1, 1_437_868_800),
        (13, "Mortynight Run", 2, 2, 1_438_473_600),
        (22, "The Rickshank Rickdemption", 3, 1, 1_491_091_200),
    ].map { id, name, season, number, airDate in
        Episode(
            id: id, name: name, code: String(format: "S%02dE%02d", season, number),
            season: season, number: number, airDate: Date(timeIntervalSince1970: airDate))
    }

    static func placeholder(_ id: Int) -> Episode {
        Episode(
            id: -id, name: "Placeholder episode", code: "S00E00", season: 0, number: id,
            airDate: Date(timeIntervalSince1970: 0))
    }
}

nonisolated extension CastMemberDetail {
    static let sample = CastMemberDetail(
        member: CastMember.samples[0], gender: "Male",
        originName: "Earth (C-137)", locationName: "Citadel of Ricks",
        episodes: Episode.samples
    )

    static let placeholder = CastMemberDetail(
        member: .placeholder(1), gender: "Gender", originName: "Origin name", locationName: "Location name",
        episodes: []
    )
}

nonisolated extension EpisodeDetail {
    static let sample = EpisodeDetail(episode: Episode.samples[0], cast: CastMember.samples)
}

nonisolated extension NetworkLogEntry {
    static let samples: [NetworkLogEntry] = [
        NetworkLogEntry(
            id: UUID(), timestamp: .now.addingTimeInterval(-62), source: .rest, label: "GET /api/character/1",
            status: 200, duration: .milliseconds(120), bytes: 1_130),
        NetworkLogEntry(
            id: UUID(), timestamp: .now.addingTimeInterval(-61), source: .rest, label: "GET /api/episode/1,2,3",
            status: 200, duration: .milliseconds(240), bytes: 10_035),
        NetworkLogEntry(
            id: UUID(), timestamp: .now.addingTimeInterval(-4), source: .graphQL, label: "CastMemberDetail",
            status: 200, duration: .milliseconds(182), bytes: 14_540),
        NetworkLogEntry(
            id: UUID(), timestamp: .now.addingTimeInterval(-2), source: .rest, label: "GET /api/character",
            status: 429, duration: .milliseconds(80), bytes: 40),
    ]
}
