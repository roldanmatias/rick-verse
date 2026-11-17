import Domain
import Foundation
import Networking

/// `CastRepository` backed by the REST API.
public struct RESTCastRepository: CastRepository {
    /// How `detail(id:)` fetches a character's episodes. This is the REST **N+1 problem**:
    /// `GET /character/1` returns 51 episode *URLs*, not episodes.
    public enum EpisodeLoading: Sendable, Equatable {
        /// One request per episode, at most `maxInFlight` at a time: 1 + N requests (52 for Rick).
        /// Kept for the Phase 8 benchmark and as a structured-concurrency reference.
        case concurrent(maxInFlight: Int)
        /// One batch request, `GET /episode/1,2,…,51`: 2 requests in total. The default.
        case batch
    }

    private let client: any HTTPClient
    private let episodeLoading: EpisodeLoading

    public init(client: any HTTPClient, episodeLoading: EpisodeLoading = .batch) {
        self.client = client
        self.episodeLoading = episodeLoading
    }

    public func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        let dto: PageDTO<CharacterDTO>
        do {
            dto = try await client.send(CharacterEndpoints.list(page: page, filter: filter))
        } catch .http(status: 404, let body) where APIError.isAPIError(body) {
            return Page(items: [], nextPage: nil)
        } catch {
            throw DomainError(error)
        }
        return try dto.toDomain { $0.toDomain() }
    }

    public func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        let character: CharacterDTO
        do {
            character = try await client.send(CharacterEndpoints.byID(id))
        } catch {
            throw DomainError(error)
        }

        let ids = character.episodeIDs
        let dtos: [EpisodeDTO]
        switch episodeLoading {
        case .batch:
            dtos = try await fetchEpisodesBatched(ids)
        case let .concurrent(maxInFlight):
            dtos = try await fetchEpisodesConcurrently(ids, maxInFlight: maxInFlight)
        }

        var episodes: [Episode] = []
        episodes.reserveCapacity(dtos.count)
        for dto in dtos {
            episodes.append(try dto.toDomain())
        }
        return character.toDetail(episodes: episodes)
    }

    private func fetchEpisodesBatched(_ ids: [Int]) async throws(DomainError) -> [EpisodeDTO] {
        guard !ids.isEmpty else { return [] }
        do {
            let batch = try await client.send(EpisodeEndpoints.byIDs(ids)).values
            return batch.ordered(by: ids, id: \.id)
        } catch {
            throw DomainError(error)
        }
    }

    private func fetchEpisodesConcurrently(_ ids: [Int], maxInFlight: Int) async throws(DomainError) -> [EpisodeDTO] {
        guard !ids.isEmpty else { return [] }
        let client = self.client
        do {
            return try await withThrowingTaskGroup(of: (Int, EpisodeDTO).self) { group in
                var results = [EpisodeDTO?](repeating: nil, count: ids.count)
                var nextIndex = 0

                func startNext() {
                    let index = nextIndex
                    let id = ids[index]
                    nextIndex += 1
                    group.addTask {
                        (index, try await client.send(EpisodeEndpoints.byID(id)))
                    }
                }

                for _ in 0..<min(max(1, maxInFlight), ids.count) {
                    startNext()
                }
                while let (index, dto) = try await group.next() {
                    results[index] = dto
                    if nextIndex < ids.count {
                        startNext()
                    }
                }
                return results.compactMap { $0 }
            }
        } catch {
            throw DomainError(any: error)
        }
    }
}

enum APIError {
    static func isAPIError(_ body: Data) -> Bool {
        (try? JSONDecoder().decode(APIErrorDTO.self, from: body)) != nil
    }
}
