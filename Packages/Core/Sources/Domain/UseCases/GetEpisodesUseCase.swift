/// Loads one page of episodes.
public struct GetEpisodesUseCase: Sendable {
    private let repository: any EpisodeRepository

    public init(repository: any EpisodeRepository) {
        self.repository = repository
    }

    public func callAsFunction(page: Int = 1) async throws(DomainError) -> Page<Episode> {
        try await repository.episodes(page: page)
    }
}
