/// Loads one episode with its cast.
public struct GetEpisodeDetailUseCase: Sendable {
    private let repository: any EpisodeRepository

    public init(repository: any EpisodeRepository) {
        self.repository = repository
    }

    public func callAsFunction(id: Int) async throws(DomainError) -> EpisodeDetail {
        try await repository.detail(id: id)
    }
}
