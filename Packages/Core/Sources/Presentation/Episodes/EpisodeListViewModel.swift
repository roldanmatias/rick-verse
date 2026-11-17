import Domain
import Foundation
import Observation

/// The Episodes tab: a paginated list, grouped into seasons.
///
/// It follows the same pagination rules as the cast list (they're shared through `Paginator` (internal)).
/// Sections are regrouped whenever a page arrives, so a season split across two pages becomes
/// one section.
@MainActor
@Observable
public final class EpisodeListViewModel {
    public var phase: ListPhase { paginator.phase }
    public var pagination: PaginationPhase { paginator.pagination }
    public var items: [Episode] { paginator.items }

    /// Episodes grouped by season, ascending. They're cached and recomputed only when `items` changes.
    public var sections: [SeasonSection] {
        let items = paginator.items
        if items != groupedItems {
            groupedItems = items
            cachedSections = SeasonSection.group(items)
        }
        return cachedSections
    }

    private let paginator = Paginator<Episode>()
    @ObservationIgnored private let getEpisodes: GetEpisodesUseCase
    @ObservationIgnored private var groupedItems: [Episode] = []
    @ObservationIgnored private var cachedSections: [SeasonSection] = []

    public init(getEpisodes: GetEpisodesUseCase) {
        self.getEpisodes = getEpisodes
    }

    /// The first load. Later calls do nothing.
    public func onAppear() async {
        guard phase == .idle else { return }
        await reload()
    }

    public func refresh() async {
        await reload()
    }

    public func retry() async {
        await reload()
    }

    public func onItemAppear(_ episode: Episode) {
        paginator.onItemAppear(episode)
    }

    public func retryNextPage() {
        paginator.retryNextPage()
    }

    private func reload() async {
        let getEpisodes = self.getEpisodes
        await paginator.reload { page async throws(DomainError) in
            try await getEpisodes(page: page)
        }
    }
}
