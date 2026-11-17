import Domain
import Foundation
import Observation

@MainActor
@Observable
final class Paginator<Item: Identifiable & Sendable> where Item.ID: Sendable {
    typealias Fetch = @MainActor (_ page: Int) async throws(DomainError) -> Page<Item>

    private(set) var phase: ListPhase = .idle
    private(set) var pagination: PaginationPhase = .idle
    private(set) var items: [Item] = []

    static var prefetchThreshold: Int { 5 }

    @ObservationIgnored private var fetch: Fetch?
    @ObservationIgnored private var nextPage: Int?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var pageTask: Task<Void, Never>?

    init() {}

    deinit {
        pageTask?.cancel()
    }

    func reload(using fetch: @escaping Fetch) async {
        generation += 1
        let current = generation

        pageTask?.cancel()
        pagination = .idle
        let previousNextPage = nextPage
        let previousFetch = self.fetch
        nextPage = nil

        if items.isEmpty {
            phase = .loading
        }

        do {
            let page = try await fetch(1)
            guard current == generation else { return }
            self.fetch = fetch
            items = page.items
            nextPage = page.nextPage
            pagination = page.hasMore ? .idle : .exhausted
            phase = items.isEmpty ? .empty : .loaded
        } catch .cancelled {
            guard current == generation else { return }
            nextPage = previousNextPage
            self.fetch = previousFetch
            if phase == .loading {
                phase = .idle
            }
        } catch {
            guard current == generation else { return }
            phase = .failed(error)
        }
    }

    func onItemAppear(_ item: Item) {
        guard pagination == .idle, phase == .loaded, nextPage != nil,
            let index = items.lastIndex(where: { $0.id == item.id }),
            index >= items.count - Self.prefetchThreshold
        else { return }
        loadNextPage()
    }

    func retryNextPage() {
        guard case .failed = pagination else { return }
        loadNextPage()
    }

    func cancel() {
        pageTask?.cancel()
    }

    private func loadNextPage() {
        guard let page = nextPage, let fetch else { return }
        pagination = .loading
        let current = generation
        pageTask = Task { [weak self] in
            await self?.fetchPage(page, using: fetch, generation: current)
        }
    }

    private func fetchPage(_ page: Int, using fetch: Fetch, generation current: Int) async {
        do {
            let result = try await fetch(page)
            guard current == generation else { return }
            var seen = Set(items.map(\.id))
            items += result.items.filter { seen.insert($0.id).inserted }
            nextPage = result.nextPage
            pagination = result.hasMore ? .idle : .exhausted
        } catch .cancelled {
            guard current == generation else { return }
            pagination = .idle
        } catch {
            guard current == generation else { return }
            pagination = .failed(error)
        }
    }
}
