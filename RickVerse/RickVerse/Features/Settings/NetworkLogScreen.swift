import Presentation
import SwiftUI

struct NetworkLogScreen: View {
    @Bindable var viewModel: NetworkLogViewModel

    var body: some View {
        List {
            Section {
                Picker("Source", selection: $viewModel.filter) {
                    Text("All").tag(NetworkLogViewModel.SourceFilter.all)
                    Text("REST").tag(NetworkLogViewModel.SourceFilter.rest)
                    Text("GraphQL").tag(NetworkLogViewModel.SourceFilter.graphQL)
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let summary = viewModel.summary(now: context.date)
                    Text("Last 10 s: \(summary.requests) requests · \(summary.totalDuration.milliseconds) ms")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.visibleEntries.isEmpty {
                ContentUnavailableView(
                    "No requests yet", systemImage: "network",
                    description: Text("Browse characters or episodes and come back.")
                )
                .listRowSeparator(.hidden)
            }
            ForEach(viewModel.visibleEntries) { entry in
                NetworkLogRow(entry: entry)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Network log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Clear") { Task { await viewModel.clear() } }
                .disabled(viewModel.entries.isEmpty)
        }
        .task { await viewModel.observe() }
    }
}

private struct NetworkLogRow: View {
    let entry: NetworkLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(entry.source == .rest ? "REST" : "GQL")
                    .font(.caption2.weight(.bold).monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.source == .rest ? Color.blue.opacity(0.15) : Color.pink.opacity(0.15), in: .capsule)
                    .foregroundStyle(entry.source == .rest ? Color.blue : Color.pink)
                Text(entry.label)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Text(statusText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(statusColor)
                Text("\(entry.duration.milliseconds) ms")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(
                "\(entry.timestamp.formatted(date: .omitted, time: .standard)) · \(Int64(entry.bytes).formatted(.byteCount(style: .file)))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusText: String {
        if entry.cancelled { return "Cancelled" }
        return entry.status.map(String.init) ?? "ERR"
    }

    private var statusColor: Color {
        if entry.cancelled { return .secondary }
        return switch entry.status {
        case .some(200..<300): .green
        case .some(400..<500): .orange
        default: .red
        }
    }
}

private extension Duration {
    var milliseconds: Int {
        Int(components.seconds * 1000 + components.attoseconds / 1_000_000_000_000_000)
    }
}
