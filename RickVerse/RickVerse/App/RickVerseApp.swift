import DataGraphQL
import SwiftUI

@main
struct RickVerseApp: App {
    @AppStorage(DataSource.storageKey) private var dataSource: DataSource = .rest

    @AppStorage(FetchPolicy.storageKey) private var cachePolicy: FetchPolicy = .networkFirst

    @State private var container = AppContainer()

    init() {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            UserDefaults.standard.removeObject(forKey: DataSource.storageKey)
            UserDefaults.standard.removeObject(forKey: FetchPolicy.storageKey)
        }

        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.viewModelFactory, container.viewModelFactory(for: dataSource, policy: cachePolicy))
                .environment(\.appActions, container.actions)
                .environment(\.dataSource, dataSource)
        }
    }
}

extension FetchPolicy {
    static let storageKey = "graphQLCachePolicy"

    var title: String {
        switch self {
        case .cacheFirst: "Cache first"
        case .networkFirst: "Network first"
        case .networkOnly: "Network only"
        case .cacheAndNetwork: "Cache, then network"
        }
    }
}
