import Apollo
import ApolloAPI
import Domain

struct GraphQLEpisodeRepository: EpisodeRepository {
    private let client: any GraphQLClient
    private let policy: FetchPolicy

    init(client: any GraphQLClient, policy: FetchPolicy) {
        self.client = client
        self.policy = policy
    }

    func episodes(page: Int) async throws(DomainError) -> Page<Episode> {
        let data: RickAndMortyAPI.EpisodePageQuery.Data
        do {
            data = try await client.fetch(RickAndMortyAPI.EpisodePageQuery(page: Int32(page)), policy: policy)
        } catch {
            throw GraphQLErrorMapper.map(error)
        }
        guard let episodes = data.episodes else { throw .invalidData }
        let items = (episodes.results ?? []).compactMap { $0?.fragments.episodeBasic.toDomain() }
        return Page(items: items, nextPage: episodes.info?.next)
    }

    func detail(id: Int) async throws(DomainError) -> EpisodeDetail {
        let data: RickAndMortyAPI.EpisodeDetailQuery.Data
        do {
            data = try await client.fetch(RickAndMortyAPI.EpisodeDetailQuery(id: String(id)), policy: policy)
        } catch {
            throw GraphQLErrorMapper.map(error)
        }
        guard let episode = data.episode else { throw .notFound }
        guard let mapped = episode.fragments.episodeBasic.toDomain() else { throw .invalidData }
        return EpisodeDetail(
            episode: mapped,
            cast: episode.characters.compactMap { $0?.fragments.castMemberBasic.toDomain() }
        )
    }
}
