import Apollo
import ApolloAPI
import Domain

struct GraphQLCastRepository: CastRepository {
    private let client: any GraphQLClient
    private let policy: FetchPolicy

    init(client: any GraphQLClient, policy: FetchPolicy) {
        self.client = client
        self.policy = policy
    }

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        let query = RickAndMortyAPI.CastPageQuery(page: Int32(page), filter: Self.filterInput(filter))
        let data: RickAndMortyAPI.CastPageQuery.Data
        do {
            data = try await client.fetch(query, policy: policy)
        } catch {
            throw GraphQLErrorMapper.map(error)
        }

        guard let characters = data.characters else { throw .invalidData }
        let items = (characters.results ?? []).compactMap { $0?.fragments.castMemberBasic.toDomain() }

        return Page(items: items, nextPage: characters.info?.next)
    }

    func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        let data: RickAndMortyAPI.CastMemberDetailQuery.Data
        do {
            data = try await client.fetch(RickAndMortyAPI.CastMemberDetailQuery(id: String(id)), policy: policy)
        } catch {
            throw GraphQLErrorMapper.map(error)
        }
        return try Self.mapDetail(data)
    }

    func detailUpdates(id: Int) -> AsyncThrowingStream<CastMemberDetail, any Error> {
        let updates = client.fetchUpdates(RickAndMortyAPI.CastMemberDetailQuery(id: String(id)), policy: policy)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await data in updates {
                        continuation.yield(try Self.mapDetail(data))
                    }
                    continuation.finish()
                } catch let error as DomainError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: GraphQLErrorMapper.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func mapDetail(_ data: RickAndMortyAPI.CastMemberDetailQuery.Data) throws(DomainError) -> CastMemberDetail {
        guard let character = data.character else { throw .notFound }

        guard let member = character.fragments.castMemberBasic.toDomain() else { throw .invalidData }

        return CastMemberDetail(
            member: member,
            gender: character.gender ?? "Unknown",
            originName: character.origin?.name ?? "unknown",
            locationName: character.location?.name ?? "unknown",

            episodes: character.episode.compactMap { $0?.fragments.episodeBasic.toDomain() }
        )
    }

    static func filterInput(_ filter: CastFilter) -> GraphQLNullable<RickAndMortyAPI.FilterCharacter> {
        guard filter.name != nil || filter.status != nil else { return .none }
        return .some(
            RickAndMortyAPI.FilterCharacter(
                name: filter.name.map { .some($0) } ?? .none,
                status: filter.status.map { .some($0.rawValue) } ?? .none
            ))
    }
}
