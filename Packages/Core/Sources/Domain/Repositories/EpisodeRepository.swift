/// Declares the episode data the Domain needs.
public protocol EpisodeRepository: Sendable {
    /// Fetches one page of episodes.
    /// - Parameter page: The 1-based page number.
    func episodes(page: Int) async throws(DomainError) -> Page<Episode>

    /// Fetches one episode with its cast.
    func detail(id: Int) async throws(DomainError) -> EpisodeDetail
}
