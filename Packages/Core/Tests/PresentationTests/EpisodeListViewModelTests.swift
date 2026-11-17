import Domain
import Foundation
import Testing

@testable import Presentation

@MainActor
struct EpisodeListViewModelTests {
    nonisolated private static let page1: [Episode] =
        (1...11).map { Episode.fixture(season: 1, number: $0) } + (1...9).map { Episode.fixture(season: 2, number: $0) }
    nonisolated private static let page2: [Episode] =
        [10].map { Episode.fixture(season: 2, number: $0) } + (1...4).map { Episode.fixture(season: 3, number: $0) }

    private func makeSUT() -> (EpisodeListViewModel, ScriptedEpisodeRepository) {
        let repository = ScriptedEpisodeRepository(pages: { page in
            page == 1 ? Page(items: Self.page1, nextPage: 2) : Page(items: Self.page2, nextPage: nil)
        })
        return (EpisodeListViewModel(getEpisodes: GetEpisodesUseCase(repository: repository)), repository)
    }

    @Test func firstPageIsGroupedBySeason() async {
        let (sut, _) = makeSUT()
        await sut.onAppear()

        #expect(sut.phase == .loaded)
        #expect(sut.sections.map(\.season) == [1, 2])
        #expect(sut.sections.map(\.episodes.count) == [11, 9])
    }

    @Test("A season split across pages becomes one section after page 2 arrives")
    func regroupsAcrossPages() async throws {
        let (sut, repository) = makeSUT()
        await sut.onAppear()

        sut.onItemAppear(try #require(sut.items.last))
        try await waitUntil { sut.pagination != .loading }

        #expect(sut.sections.map(\.season) == [1, 2, 3])
        #expect(sut.sections[1].episodes.map(\.number) == Array(1...10))
        #expect(sut.pagination == .exhausted)
        #expect(await repository.pageCalls == [1, 2])
    }

    @Test func onAppearLoadsOnce() async {
        let (sut, repository) = makeSUT()
        await sut.onAppear()
        await sut.onAppear()
        #expect(await repository.pageCalls == [1])
    }

    @Test func failureThenRetry() async {
        let attempts = Counter()
        let repository = ScriptedEpisodeRepository(pages: { _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .server }
            return Page(items: Self.page1, nextPage: nil)
        })
        let sut = EpisodeListViewModel(getEpisodes: GetEpisodesUseCase(repository: repository))

        await sut.onAppear()
        #expect(sut.phase == .failed(.server))

        await sut.retry()
        #expect(sut.phase == .loaded)
        #expect(sut.sections.count == 2)
    }
}
