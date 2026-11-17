import Domain
import Foundation
import Testing

actor ScriptedCastRepository: CastRepository {
    typealias Handler = @Sendable (_ page: Int, _ filter: CastFilter) async throws(DomainError) -> Page<CastMember>

    struct Call: Equatable {
        let page: Int
        let filter: CastFilter
    }

    private(set) var calls: [Call] = []
    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        calls.append(Call(page: page, filter: filter))
        return try await handler(page, filter)
    }

    func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        throw .unknown
    }
}

actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
}

extension CastMember {
    static func fixture(_ id: Int, name: String? = nil) -> CastMember {
        CastMember(
            id: id, name: name ?? "Character \(id)", status: .alive, species: "Human",
            imageURL: URL(string: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg")!
        )
    }

    static func page(_ number: Int, size: Int = 20) -> [CastMember] {
        let start = (number - 1) * size + 1
        return (start..<start + size).map { fixture($0) }
    }
}

@MainActor
func waitUntil(
    _ condition: @MainActor () async -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    for _ in 0..<200 {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("Timed out waiting for condition", sourceLocation: sourceLocation)
    throw CancellationError()
}

actor ScriptedEpisodeRepository: EpisodeRepository {
    typealias PageHandler = @Sendable (_ page: Int) async throws(DomainError) -> Page<Episode>
    typealias DetailHandler = @Sendable (_ id: Int) async throws(DomainError) -> EpisodeDetail

    private(set) var pageCalls: [Int] = []
    private(set) var detailCalls: [Int] = []
    private let pageHandler: PageHandler
    private let detailHandler: DetailHandler

    init(
        pages: @escaping PageHandler = { _ throws(DomainError) in throw .unknown },
        detail: @escaping DetailHandler = { _ throws(DomainError) in throw .unknown }
    ) {
        pageHandler = pages
        detailHandler = detail
    }

    func episodes(page: Int) async throws(DomainError) -> Page<Episode> {
        pageCalls.append(page)
        return try await pageHandler(page)
    }

    func detail(id: Int) async throws(DomainError) -> EpisodeDetail {
        detailCalls.append(id)
        return try await detailHandler(id)
    }
}

actor ScriptedCastDetailRepository: CastRepository {
    typealias Handler = @Sendable (_ id: Int) async throws(DomainError) -> CastMemberDetail

    private(set) var detailCalls: [Int] = []
    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        throw .unknown
    }

    func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        detailCalls.append(id)
        return try await handler(id)
    }
}

extension Episode {
    static func fixture(season: Int, number: Int, id: Int? = nil) -> Episode {
        Episode(
            id: id ?? season * 100 + number,
            name: "Episode \(number)",
            code: String(format: "S%02dE%02d", season, number),
            season: season, number: number, airDate: nil
        )
    }
}

struct StreamingCastRepository: CastRepository {
    let values: [CastMemberDetail]
    var failure: DomainError?

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> { throw .unknown }
    func detail(id: Int) async throws(DomainError) -> CastMemberDetail { throw .unknown }

    func detailUpdates(id: Int) -> AsyncThrowingStream<CastMemberDetail, any Error> {
        AsyncThrowingStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            if let failure {
                continuation.finish(throwing: failure)
            } else {
                continuation.finish()
            }
        }
    }
}
