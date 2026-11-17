import Domain
import Testing

@Suite("Detail and episode use cases")
struct OtherUseCasesTests {
    @Test func castMemberDetailForwardsIDAndReturnsDetail() async throws {
        let detail = CastMemberDetail(
            member: .fixture(id: 42), gender: "Male", originName: "Earth (C-137)",
            locationName: "Citadel of Ricks", episodes: [.fixture()]
        )
        let repository = StubCastRepository(detailResult: .success(detail))
        let sut = GetCastMemberDetailUseCase(repository: repository)

        let result = try await sut(id: 42)

        #expect(result == detail)
        #expect(result.id == 42)
        #expect(await repository.detailCalls == [42])
    }

    @Test func castMemberDetailRethrows() async {
        let sut = GetCastMemberDetailUseCase(repository: StubCastRepository(detailResult: .failure(.notFound)))
        await #expect(throws: DomainError.notFound) { try await sut(id: 999) }
    }

    @Test func episodesForwardsPage() async throws {
        let page = Page(items: [Episode.fixture()], nextPage: nil)
        let repository = StubEpisodeRepository(episodesResult: .success(page))
        let sut = GetEpisodesUseCase(repository: repository)

        let first = try await sut()
        _ = try await sut(page: 2)

        #expect(first == page)
        #expect(!first.hasMore)
        #expect(await repository.episodesCalls == [1, 2])
    }

    @Test func episodesRethrows() async {
        let sut = GetEpisodesUseCase(repository: StubEpisodeRepository(episodesResult: .failure(.timeout)))
        await #expect(throws: DomainError.timeout) { try await sut() }
    }

    @Test func episodeDetailForwardsIDAndReturnsDetail() async throws {
        let detail = EpisodeDetail(episode: .fixture(id: 7), cast: [.fixture(id: 1), .fixture(id: 2)])
        let repository = StubEpisodeRepository(detailResult: .success(detail))
        let sut = GetEpisodeDetailUseCase(repository: repository)

        let result = try await sut(id: 7)

        #expect(result == detail)
        #expect(result.id == 7)
        #expect(await repository.detailCalls == [7])
    }

    @Test func episodeDetailRethrows() async {
        let sut = GetEpisodeDetailUseCase(repository: StubEpisodeRepository(detailResult: .failure(.server)))
        await #expect(throws: DomainError.server) { try await sut(id: 7) }
    }
}

@Suite("Page")
struct PageTests {
    @Test("hasMore reflects nextPage", arguments: [(Int?.none, false), (2, true)])
    func hasMore(nextPage: Int?, expected: Bool) {
        #expect(Page<Int>(items: [], nextPage: nextPage).hasMore == expected)
    }
}
