import Domain
import Foundation
import Observation

/// The episode detail screen: the episode and its cast.
@MainActor
@Observable
public final class EpisodeDetailViewModel {
    public enum State: Equatable, Sendable {
        case loading
        case loaded(EpisodeDetail)
        case failed(DomainError)
    }

    public let id: Int
    public private(set) var state: State = .loading

    @ObservationIgnored private let getDetail: GetEpisodeDetailUseCase
    @ObservationIgnored private var isLoading = false

    public init(id: Int, getDetail: GetEpisodeDetailUseCase) {
        self.id = id
        self.getDetail = getDetail
    }

    /// Call this from `.task`. A loaded screen doesn't refetch when it reappears.
    public func load() async {
        guard !isLoaded, !isLoading else { return }
        await performLoad()
    }

    public func retry() async {
        guard !isLoading else { return }
        state = .loading
        await performLoad()
    }

    private var isLoaded: Bool {
        if case .loaded = state { true } else { false }
    }

    private func performLoad() async {
        isLoading = true
        defer { isLoading = false }
        do {
            state = .loaded(try await getDetail(id: id))
        } catch .cancelled {
        } catch {
            state = .failed(error)
        }
    }
}
