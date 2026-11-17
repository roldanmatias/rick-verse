import Domain

actor StubEpisodeRepository: EpisodeRepository {
    private(set) var episodesCalls: [Int] = []
    private(set) var detailCalls: [Int] = []

    private let episodesResult: Result<Page<Episode>, DomainError>
    private let detailResult: Result<EpisodeDetail, DomainError>

    init(
        episodesResult: Result<Page<Episode>, DomainError> = .success(Page(items: [], nextPage: nil)),
        detailResult: Result<EpisodeDetail, DomainError> = .failure(.notFound)
    ) {
        self.episodesResult = episodesResult
        self.detailResult = detailResult
    }

    func episodes(page: Int) async throws(DomainError) -> Page<Episode> {
        episodesCalls.append(page)
        return try episodesResult.get()
    }

    func detail(id: Int) async throws(DomainError) -> EpisodeDetail {
        detailCalls.append(id)
        return try detailResult.get()
    }
}
