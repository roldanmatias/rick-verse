import Domain
import Networking

/// `EpisodeRepository` backed by the REST API.
public struct RESTEpisodeRepository: EpisodeRepository {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func episodes(page: Int) async throws(DomainError) -> Page<Episode> {
        let dto: PageDTO<EpisodeDTO>
        do {
            dto = try await client.send(EpisodeEndpoints.list(page: page))
        } catch {
            throw DomainError(error)
        }
        return try dto.toDomain { dto throws(DomainError) in try dto.toDomain() }
    }

    /// The episode, then its cast in one batch request: 2 requests in total.
    public func detail(id: Int) async throws(DomainError) -> EpisodeDetail {
        let episodeDTO: EpisodeDTO
        do {
            episodeDTO = try await client.send(EpisodeEndpoints.byID(id))
        } catch {
            throw DomainError(error)
        }
        let episode = try episodeDTO.toDomain()

        let ids = episodeDTO.characterIDs
        guard !ids.isEmpty else { return EpisodeDetail(episode: episode, cast: []) }

        let characters: [CharacterDTO]
        do {
            characters = try await client.send(CharacterEndpoints.byIDs(ids)).values
        } catch {
            throw DomainError(error)
        }
        return EpisodeDetail(
            episode: episode,
            cast: characters.ordered(by: ids, id: \.id).map { $0.toDomain() }
        )
    }
}
