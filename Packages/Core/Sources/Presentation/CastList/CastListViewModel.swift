import Domain
import Foundation
import Observation

/// The state and intents of the cast list screen: search, status filter, and pagination.
///
/// `@MainActor` because every state change drives the UI. `@Observable` so SwiftUI re-renders
/// only the views that read a property that changed. This module never imports SwiftUI.
/// Copy, colors, and layout belong to the app.
///
/// Search-specific rules live here:
/// - **Debounce.** Each `query` change cancels the pending reload and schedules a new one.
/// - **Immediate filter.** A `statusFilter` change reloads right away.
///
/// Pagination, stale-response protection, and silent cancellation live in the shared `Paginator` (internal).
@MainActor
@Observable
public final class CastListViewModel {
    public typealias Phase = ListPhase

    public var phase: ListPhase { paginator.phase }
    public var pagination: PaginationPhase { paginator.pagination }
    public var items: [CastMember] { paginator.items }

    /// Bound to `.searchable`. Each change schedules a debounced reload.
    public var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleReload(after: debounce)
        }
    }

    /// `nil` means "All". Each change reloads immediately.
    public var statusFilter: CastMember.Status? {
        didSet {
            guard statusFilter != oldValue else { return }
            scheduleReload(after: .zero)
        }
    }

    private let paginator = Paginator<CastMember>()
    @ObservationIgnored private let searchCast: SearchCastUseCase
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    /// - Parameters:
    ///   - searchCast: The use case that trims the query and fetches a page.
    ///   - debounce: Pass `.zero` in tests. A larger codebase would inject a `Clock` instead.
    public init(searchCast: SearchCastUseCase, debounce: Duration = .milliseconds(400)) {
        self.searchCast = searchCast
        self.debounce = debounce
    }

    deinit {
        reloadTask?.cancel()
    }

    public func onAppear() async {
        guard phase == .idle else { return }
        await reload()
    }

    /// Pull to refresh. The current items stay on screen until page 1 arrives.
    public func refresh() async {
        reloadTask?.cancel()
        await reload()
    }

    /// Retry from the full-screen error state.
    public func retry() async {
        reloadTask?.cancel()
        await reload()
    }

    /// Call this from each row's `.onAppear`. Loads the next page when `item` is near the end.
    public func onItemAppear(_ item: CastMember) {
        paginator.onItemAppear(item)
    }

    /// Retry from the "Couldn't load more" footer.
    public func retryNextPage() {
        paginator.retryNextPage()
    }

    private func scheduleReload(after delay: Duration) {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.reload()
        }
    }

    private func reload() async {
        let filter = CastFilter(name: query, status: statusFilter)
        let searchCast = self.searchCast
        await paginator.reload { page async throws(DomainError) in
            try await searchCast(filter: filter, page: page)
        }
    }
}
