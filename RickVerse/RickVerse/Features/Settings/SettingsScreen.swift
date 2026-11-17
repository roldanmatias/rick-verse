import DataGraphQL
import Presentation
import SwiftUI

struct SettingsScreen: View {
    @AppStorage(DataSource.storageKey) private var dataSource: DataSource = .rest
    @AppStorage(FetchPolicy.storageKey) private var cachePolicy: FetchPolicy = .networkFirst
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.appActions) private var actions

    @State private var networkLog: NetworkLogViewModel?
    @State private var isConfirmingClear = false
    @State private var cacheMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Data source", selection: $dataSource) {
                    ForEach(DataSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("dataSourcePicker")
            } header: {
                Text("Data source")
            } footer: {
                Text("Switching reloads all screens.")
            }

            Section {
                Picker("Cache policy", selection: $cachePolicy) {
                    ForEach(FetchPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                .pickerStyle(.menu)

                Button("Clear GraphQL cache", role: .destructive) {
                    isConfirmingClear = true
                }
                .confirmationDialog("Clear the GraphQL cache?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
                    Button("Clear cache", role: .destructive) { Task { await clearCache() } }
                } message: {
                    Text("The next GraphQL read goes to the network.")
                }
            } header: {
                Text("GraphQL")
            } footer: {
                if let cacheMessage {
                    Text(cacheMessage)
                } else {
                    Text(
                        """
                        Applies to screens opened after the change. Watch the network log: \
                        with Cache first, reopening a character makes zero requests.
                        """
                    )
                }
            }
            .disabled(dataSource != .graphQL)

            Section("Diagnostics") {
                if let networkLog {
                    NavigationLink(value: SettingsRoute.networkLog) {
                        LabeledContent("Network log") {
                            Text(networkLog.entries.count, format: .number)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Self.version)
                Link(destination: Self.sourceCode) {
                    Label("Source code on GitHub", systemImage: "arrow.up.right.square")
                }
                Link(destination: Self.apiWebsite) {
                    Label("Data: rickandmortyapi.com", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .networkLog:
                if let networkLog {
                    NetworkLogScreen(viewModel: networkLog)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: dataSource)
        .task {
            if networkLog == nil {
                networkLog = factory.makeNetworkLog()
            }
            await networkLog?.observe()
        }
    }

    private func clearCache() async {
        do {
            try await actions.clearGraphQLCache()
            cacheMessage = "Cache cleared."
        } catch {
            cacheMessage = "Couldn't clear the cache."
        }
        try? await Task.sleep(for: .seconds(3))
        cacheMessage = nil
    }

    private static let apiWebsite = URL(string: "https://rickandmortyapi.com")!
    private static let sourceCode = URL(string: "https://github.com/roldanmatias/rick-verse")!

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack { SettingsScreen() }
        .environment(\.viewModelFactory, .preview())
}

enum SettingsRoute: Hashable {
    case networkLog
}
