import Domain
import Foundation
import Testing

@testable import Presentation

@MainActor
struct CastDetailViewModelTests {
    nonisolated private static func detail(episodes: [Episode]) -> CastMemberDetail {
        CastMemberDetail(
            member: .fixture(1, name: "Rick Sanchez"), gender: "Male",
            originName: "Earth (C-137)", locationName: "Citadel of Ricks", episodes: episodes)
    }

    private func makeSUT(handler: @escaping ScriptedCastDetailRepository.Handler) -> (CastDetailViewModel, ScriptedCastDetailRepository) {
        let repository = ScriptedCastDetailRepository(handler: handler)
        return (CastDetailViewModel(id: 1, getDetail: GetCastMemberDetailUseCase(repository: repository)), repository)
    }

    @Test("Loads the detail and groups episodes by season, ascending")
    func loadsAndGroups() async {
        let episodes: [Episode] = [
            .fixture(season: 3, number: 1), .fixture(season: 1, number: 2),
            .fixture(season: 1, number: 1), .fixture(season: 2, number: 10), .fixture(season: 2, number: 2),
        ]
        let detail = Self.detail(episodes: episodes)
        let (sut, repository) = makeSUT { _ in detail }
        #expect(sut.state == .loading)

        await sut.load()

        #expect(sut.state == .loaded(detail))
        #expect(sut.episodesBySeason.map(\.season) == [1, 2, 3])
        #expect(sut.episodesBySeason[1].episodes.map(\.code) == ["S02E02", "S02E10"])
        #expect(await repository.detailCalls == [1])
    }

    @Test("load() after a successful load doesn't refetch (.task reruns when popping back)")
    func loadIsIdempotent() async {
        let (sut, repository) = makeSUT { _ in Self.detail(episodes: []) }
        await sut.load()
        await sut.load()
        #expect(await repository.detailCalls.count == 1)
    }

    @Test func concurrentLoadsFetchOnce() async {
        let gate = Gate()
        let (sut, repository) = makeSUT { _ in
            await gate.wait()
            return Self.detail(episodes: [])
        }
        async let first: Void = sut.load()
        async let second: Void = sut.load()
        await gate.open()
        _ = await (first, second)
        #expect(await repository.detailCalls.count == 1)
    }

    @Test func failureThenRetry() async {
        let attempts = Counter()
        let (sut, _) = makeSUT { _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .notFound }
            return Self.detail(episodes: [.fixture(season: 1, number: 1)])
        }

        await sut.load()
        #expect(sut.state == .failed(.notFound))

        await sut.retry()
        guard case .loaded = sut.state else {
            Issue.record("Expected .loaded, got \(sut.state)")
            return
        }
        #expect(sut.episodesBySeason.count == 1)
    }

    @Test("Cancellation stays .loading, and the next load() tries again")
    func cancellationIsSilent() async {
        let attempts = Counter()
        let (sut, repository) = makeSUT { _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .cancelled }
            return Self.detail(episodes: [])
        }

        await sut.load()
        #expect(sut.state == .loading)

        await sut.load()
        #expect(sut.state == .loaded(Self.detail(episodes: [])))
        #expect(await repository.detailCalls.count == 2)
    }
}

@MainActor
struct EpisodeDetailViewModelTests {
    nonisolated private static let detail = EpisodeDetail(
        episode: .fixture(season: 1, number: 1, id: 1),
        cast: [.fixture(1, name: "Rick Sanchez"), .fixture(2, name: "Morty Smith")]
    )

    @Test func loads() async {
        let repository = ScriptedEpisodeRepository(detail: { _ in Self.detail })
        let sut = EpisodeDetailViewModel(id: 1, getDetail: GetEpisodeDetailUseCase(repository: repository))

        await sut.load()
        await sut.load()

        #expect(sut.state == .loaded(Self.detail))
        #expect(await repository.detailCalls == [1])
    }

    @Test func failureThenRetry() async {
        let attempts = Counter()
        let repository = ScriptedEpisodeRepository(detail: { _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .offline }
            return Self.detail
        })
        let sut = EpisodeDetailViewModel(id: 1, getDetail: GetEpisodeDetailUseCase(repository: repository))

        await sut.load()
        #expect(sut.state == .failed(.offline))

        await sut.retry()
        #expect(sut.state == .loaded(Self.detail))
    }
}
