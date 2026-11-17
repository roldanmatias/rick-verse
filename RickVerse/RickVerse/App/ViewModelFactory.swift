import Presentation
import SwiftUI

struct ViewModelFactory {
    var makeCastList: @MainActor () -> CastListViewModel
    var makeCastDetail: @MainActor (_ id: Int) -> CastDetailViewModel
    var makeEpisodeList: @MainActor () -> EpisodeListViewModel
    var makeEpisodeDetail: @MainActor (_ id: Int) -> EpisodeDetailViewModel
    var makeNetworkLog: @MainActor () -> NetworkLogViewModel
}

struct AppActions {
    var clearGraphQLCache: @MainActor () async throws -> Void
}

extension ViewModelFactory {
    static let unimplemented = ViewModelFactory(
        makeCastList: { fatalError(Self.notInjected) },
        makeCastDetail: { _ in fatalError(Self.notInjected) },
        makeEpisodeList: { fatalError(Self.notInjected) },
        makeEpisodeDetail: { _ in fatalError(Self.notInjected) },
        makeNetworkLog: { fatalError(Self.notInjected) }
    )

    private static let notInjected = "ViewModelFactory not injected. Use .environment(\\.viewModelFactory, …)"
}

extension EnvironmentValues {
    @Entry var viewModelFactory: ViewModelFactory = .unimplemented
    @Entry var appActions: AppActions = AppActions(clearGraphQLCache: {})
}
