import Domain
import Foundation
import Testing

@testable import Presentation

@MainActor
struct CastListViewModelTests {
    private func makeSUT(
        debounce: Duration = .zero,
        handler: @escaping ScriptedCastRepository.Handler
    ) -> (CastListViewModel, ScriptedCastRepository) {
        let repository = ScriptedCastRepository(handler: handler)
        let viewModel = CastListViewModel(searchCast: SearchCastUseCase(repository: repository), debounce: debounce)
        return (viewModel, repository)
    }

    private static func paged(pages: Int = 3) -> ScriptedCastRepository.Handler {
        { page, _ in Page(items: CastMember.page(page), nextPage: page < pages ? page + 1 : nil) }
    }

    @Test("onAppear goes .idle → .loading → .loaded")
    func firstLoad() async throws {
        let gate = Gate()
        let (sut, _) = makeSUT { page, _ in
            await gate.wait()
            return Page(items: CastMember.page(page), nextPage: 2)
        }
        #expect(sut.phase == .idle)

        async let load: Void = sut.onAppear()
        try await waitUntil { sut.phase == .loading }
        await gate.open()
        await load

        #expect(sut.phase == .loaded)
        #expect(sut.items.count == 20)
        #expect(sut.pagination == .idle)
    }

    @Test func onAppearLoadsOnlyOnce() async {
        let (sut, repository) = makeSUT(handler: Self.paged())
        await sut.onAppear()
        await sut.onAppear()
        #expect(await repository.calls.count == 1)
    }

    @Test func emptyPageIsEmpty() async {
        let (sut, _) = makeSUT { _, _ in Page(items: [], nextPage: nil) }
        await sut.onAppear()
        #expect(sut.phase == .empty)
        #expect(sut.pagination == .exhausted)
    }

    @Test func singlePageIsExhausted() async {
        let (sut, _) = makeSUT { _, _ in Page(items: CastMember.page(1, size: 3), nextPage: nil) }
        await sut.onAppear()
        #expect(sut.phase == .loaded)
        #expect(sut.pagination == .exhausted)
    }

    @Test func errorIsFailed() async {
        let (sut, _) = makeSUT { _, _ throws(DomainError) in throw .offline }
        await sut.onAppear()
        #expect(sut.phase == .failed(.offline))
    }

    @Test("Cancellation never shows an error, and the next onAppear loads again")
    func cancellationIsSilent() async {
        let attempts = Counter()
        let (sut, repository) = makeSUT { page, _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .cancelled }
            return Page(items: CastMember.page(page), nextPage: nil)
        }

        await sut.onAppear()
        #expect(sut.phase == .idle)

        await sut.onAppear()
        #expect(sut.phase == .loaded)
        #expect(await repository.calls.count == 2)
    }

    @Test func retryRecoversFromFailure() async {
        let attempts = Counter()
        let (sut, _) = makeSUT { page, _ throws(DomainError) in
            if await attempts.increment() == 1 { throw .server }
            return Page(items: CastMember.page(page), nextPage: nil)
        }

        await sut.onAppear()
        #expect(sut.phase == .failed(.server))

        await sut.retry()
        #expect(sut.phase == .loaded)
        #expect(sut.items.count == 20)
    }

    @Test func lastItemLoadsNextPageAndAppends() async throws {
        let (sut, repository) = makeSUT(handler: Self.paged())
        await sut.onAppear()

        sut.onItemAppear(try #require(sut.items.last))
        try await waitUntil { sut.pagination != .loading }

        #expect(sut.items.map(\.id) == Array(1...40))
        #expect(sut.pagination == .idle)
        #expect(await repository.calls.map(\.page) == [1, 2])
    }

    @Test("Only the last 5 rows trigger prefetch")
    func prefetchThreshold() async throws {
        let (sut, repository) = makeSUT(handler: Self.paged())
        await sut.onAppear()

        sut.onItemAppear(sut.items[14])
        #expect(sut.pagination == .idle)

        sut.onItemAppear(sut.items[15])
        #expect(sut.pagination == .loading)
        try await waitUntil { sut.pagination != .loading }
        #expect(await repository.calls.map(\.page) == [1, 2])
    }

    @Test("Doesn't fire twice while a page is loading")
    func noDoubleFetch() async throws {
        let gate = Gate()
        let (sut, repository) = makeSUT { page, _ in
            if page == 2 { await gate.wait() }
            return Page(items: CastMember.page(page), nextPage: page + 1)
        }
        await sut.onAppear()

        let last = try #require(sut.items.last)
        sut.onItemAppear(last)
        sut.onItemAppear(last)
        sut.onItemAppear(sut.items[18])
        await gate.open()
        try await waitUntil { sut.pagination != .loading }

        #expect(await repository.calls.map(\.page) == [1, 2])
    }

    @Test func lastPageIsExhaustedAndStopsPaginating() async throws {
        let (sut, repository) = makeSUT(handler: Self.paged(pages: 2))
        await sut.onAppear()

        sut.onItemAppear(try #require(sut.items.last))
        try await waitUntil { sut.pagination != .loading }
        #expect(sut.pagination == .exhausted)

        sut.onItemAppear(try #require(sut.items.last))
        #expect(await repository.calls.count == 2)
    }

    @Test func deduplicatesAcrossPages() async throws {
        let (sut, _) = makeSUT { page, _ in
            page == 1
                ? Page(items: CastMember.page(1), nextPage: 2)
                : Page(items: [.fixture(20), .fixture(21), .fixture(21), .fixture(22)], nextPage: nil)
        }
        await sut.onAppear()

        sut.onItemAppear(try #require(sut.items.last))
        try await waitUntil { sut.pagination != .loading }

        #expect(sut.items.map(\.id) == Array(1...22))
    }

    @Test("A page-2 failure keeps page 1, and retryNextPage recovers")
    func nextPageFailure() async throws {
        let attempts = Counter()
        let (sut, _) = makeSUT { page, _ throws(DomainError) in
            if page == 2, await attempts.increment() == 1 { throw .timeout }
            return Page(items: CastMember.page(page), nextPage: page < 2 ? page + 1 : nil)
        }
        await sut.onAppear()

        sut.onItemAppear(try #require(sut.items.last))
        try await waitUntil { sut.pagination != .loading }
        #expect(sut.pagination == .failed(.timeout))
        #expect(sut.items.count == 20)
        #expect(sut.phase == .loaded)

        sut.retryNextPage()
        try await waitUntil { sut.pagination != .loading }
        #expect(sut.pagination == .exhausted)
        #expect(sut.items.count == 40)
    }

    @Test("Stale response: slow \"ri\" arrives after fast \"rick\" and is dropped")
    func staleResponseIsDropped() async throws {
        let gate = Gate()
        let ri = [CastMember.fixture(100, name: "Rival Rick")]
        let rick = [CastMember.fixture(1, name: "Rick Sanchez")]
        let (sut, repository) = makeSUT(debounce: .seconds(3600)) { _, filter in
            if filter.name == "ri" {
                await gate.wait()
                return Page(items: ri, nextPage: nil)
            }
            return Page(items: rick, nextPage: nil)
        }

        sut.query = "ri"
        async let slow: Void = sut.refresh()
        try await waitUntil { await repository.calls.count == 1 }

        sut.query = "rick"
        await sut.refresh()
        #expect(sut.items == rick)

        await gate.open()
        await slow

        #expect(sut.items == rick)
        #expect(sut.phase == .loaded)
    }

    @Test("Typing quickly sends only the last query")
    func debounceCollapsesKeystrokes() async throws {
        let (sut, repository) = makeSUT(debounce: .milliseconds(50)) { _, filter in
            Page(items: [.fixture(1, name: filter.name ?? "all")], nextPage: nil)
        }

        sut.query = "r"
        sut.query = "ri"
        sut.query = "ric"
        sut.query = "rick"
        try await waitUntil { sut.phase == .loaded }

        #expect(await repository.calls.map(\.filter.name) == ["rick"])
        #expect(sut.items.first?.name == "rick")
    }

    @Test func clearingTheQueryReloadsEverything() async throws {
        let (sut, repository) = makeSUT { page, _ in Page(items: CastMember.page(page), nextPage: nil) }
        sut.query = "rick"
        try await waitUntil { await repository.calls.count == 1 }

        sut.query = ""
        try await waitUntil { await repository.calls.count == 2 }

        #expect(await repository.calls.map(\.filter.name) == ["rick", nil])
    }

    @Test func statusFilterReloadsWithStatus() async throws {
        let (sut, repository) = makeSUT(debounce: .seconds(3600)) { _, _ in
            Page(items: [.fixture(1)], nextPage: nil)
        }
        await sut.onAppear()

        sut.statusFilter = .dead
        try await waitUntil { await repository.calls.count == 2 }

        let call = try #require(await repository.calls.last)
        #expect(call.filter.status == .dead)
        #expect(call.page == 1)
    }

    @Test func settingTheSameValueDoesNotReload() async throws {
        let (sut, repository) = makeSUT(handler: Self.paged())
        await sut.onAppear()

        sut.query = ""
        sut.statusFilter = nil
        try await Task.sleep(for: .milliseconds(50))

        #expect(await repository.calls.count == 1)
    }

    @Test("Refresh keeps the items visible until the new page 1 arrives")
    func refreshKeepsItems() async throws {
        let gate = Gate()
        let attempts = Counter()
        let (sut, _) = makeSUT { _, _ in
            if await attempts.increment() == 2 {
                await gate.wait()
                return Page(items: [.fixture(99)], nextPage: nil)
            }
            return Page(items: CastMember.page(1), nextPage: 2)
        }
        await sut.onAppear()

        async let refresh: Void = sut.refresh()
        try await waitUntil { await attempts.value == 2 }
        #expect(sut.phase == .loaded)
        #expect(sut.items.count == 20)

        await gate.open()
        await refresh
        #expect(sut.items.map(\.id) == [99])
    }

    @Test("Refreshing mid-pagination drops the old page")
    func refreshDropsInFlightPage() async throws {
        let gate = Gate()
        let (sut, _) = makeSUT { page, _ in
            if page == 2 {
                await gate.wait()
            }
            return Page(items: CastMember.page(page), nextPage: page + 1)
        }
        await sut.onAppear()
        sut.onItemAppear(try #require(sut.items.last))
        #expect(sut.pagination == .loading)

        await sut.refresh()
        await gate.open()
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.items.map(\.id) == Array(1...20))
        #expect(sut.pagination == .idle)
    }
}

actor Counter {
    private(set) var value = 0

    func increment() -> Int {
        value += 1
        return value
    }
}
