import Domain
import Foundation
import Observation

/// The character detail screen: one load, a retry, and episodes grouped by season.
@MainActor
@Observable
public final class CastDetailViewModel {
    public enum State: Equatable, Sendable {
        case loading
        case loaded(CastMemberDetail)
        case failed(DomainError)
    }

    public let id: Int
    public private(set) var state: State = .loading
    /// It's computed once on load, not on every read, so SwiftUI re-renders don't regroup.
    public private(set) var episodesBySeason: [SeasonSection] = []

    @ObservationIgnored private let getDetail: GetCastMemberDetailUseCase
    @ObservationIgnored private var isLoading = false

    public init(id: Int, getDetail: GetCastMemberDetailUseCase) {
        self.id = id
        self.getDetail = getDetail
    }

    /// Call this from `.task`. `.task` runs again whenever the view reappears (for example,
    /// after popping back from an episode), so a loaded screen doesn't refetch.
    public func load() async {
        guard !isLoaded, !isLoading else { return }
        await consumeUpdates()
    }

    public func retry() async {
        guard !isLoading else { return }
        state = .loading
        await consumeUpdates()
    }

    private var isLoaded: Bool {
        if case .loaded = state { true } else { false }
    }

    private func consumeUpdates() async {
        isLoading = true
        defer { isLoading = false }
        do {
            for try await detail in getDetail.updates(id: id) {
                if case let .loaded(current) = state, current == detail { continue }
                episodesBySeason = SeasonSection.group(detail.episodes)
                state = .loaded(detail)
            }
        } catch {
            let domainError = error as? DomainError ?? .unknown

            guard domainError != .cancelled else { return }

            if isLoaded { return }
            state = .failed(domainError)
        }
    }
}
