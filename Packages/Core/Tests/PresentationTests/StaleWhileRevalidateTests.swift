import Domain
import Foundation
import Testing

@testable import Presentation

@MainActor
struct StaleWhileRevalidateTests {
    nonisolated private static func detail(name: String, episodes: [Episode] = [.fixture(season: 1, number: 1)]) -> CastMemberDetail {
        CastMemberDetail(
            member: .fixture(1, name: name), gender: "Male", originName: "Earth",
            locationName: "Citadel", episodes: episodes)
    }

    private func makeSUT(_ repository: StreamingCastRepository) -> CastDetailViewModel {
        CastDetailViewModel(id: 1, getDetail: GetCastMemberDetailUseCase(repository: repository))
    }

    @Test("Cached then fresh: the fresh value wins, and the seasons are regrouped")
    func freshReplacesCached() async {
        let cached = Self.detail(name: "Rick (cached)")
        let fresh = Self.detail(name: "Rick (fresh)", episodes: [.fixture(season: 1, number: 1), .fixture(season: 2, number: 1)])
        let sut = makeSUT(StreamingCastRepository(values: [cached, fresh]))

        await sut.load()

        #expect(sut.state == .loaded(fresh))
        #expect(sut.episodesBySeason.map(\.season) == [1, 2])
    }

    @Test("A revalidation failure after cached data keeps the cached data on screen")
    func revalidationFailureKeepsStale() async {
        let cached = Self.detail(name: "Rick (cached)")
        let sut = makeSUT(StreamingCastRepository(values: [cached], failure: .offline))

        await sut.load()

        #expect(sut.state == .loaded(cached))
    }

    @Test("A failure before any value is a normal error state")
    func failureWithoutValue() async {
        let sut = makeSUT(StreamingCastRepository(values: [], failure: .server))
        await sut.load()
        #expect(sut.state == .failed(.server))
    }

    @Test("Cancellation stays .loading")
    func cancellation() async {
        let sut = makeSUT(StreamingCastRepository(values: [], failure: .cancelled))
        await sut.load()
        #expect(sut.state == .loading)
    }
}
