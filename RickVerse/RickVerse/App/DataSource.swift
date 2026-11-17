import SwiftUI

enum DataSource: String, CaseIterable, Identifiable {
    case rest
    case graphQL

    static let storageKey = "dataSource"

    var id: Self { self }

    var title: String {
        switch self {
        case .rest: "REST"
        case .graphQL: "GraphQL"
        }
    }
}

extension EnvironmentValues {
    @Entry var dataSource: DataSource = .rest
}
