import Foundation
import Observation

/// One row of the network log, as the screen needs it.
///
/// It's defined here, and not reused from `Networking.NetworkEvent`, so Presentation depends only
/// on Domain (the guide's `Package.swift`). The app maps `NetworkLog` onto this type.
public struct NetworkLogEntry: Identifiable, Equatable, Sendable {
    public enum Source: Sendable, Equatable {
        case rest
        case graphQL
    }

    public let id: UUID
    public let timestamp: Date
    public let source: Source
    public let label: String
    public let status: Int?
    public let duration: Duration
    public let bytes: Int
    /// Cancelled by the app (for example, a newer search replaced it), not a failure.
    public let cancelled: Bool

    public init(
        id: UUID, timestamp: Date, source: Source, label: String, status: Int?, duration: Duration, bytes: Int,
        cancelled: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.label = label
        self.status = status
        self.duration = duration
        self.bytes = bytes
        self.cancelled = cancelled
    }
}

/// The live network log: every REST and GraphQL round trip, newest first.
@MainActor
@Observable
public final class NetworkLogViewModel {
    public enum SourceFilter: String, CaseIterable, Sendable, Identifiable {
        case all
        case rest
        case graphQL

        public var id: Self { self }
    }

    public struct Summary: Equatable, Sendable {
        public let requests: Int
        public let totalDuration: Duration
    }

    public var filter: SourceFilter = .all
    /// All entries, newest first.
    public private(set) var entries: [NetworkLogEntry] = []

    public var visibleEntries: [NetworkLogEntry] {
        switch filter {
        case .all: entries
        case .rest: entries.filter { $0.source == .rest }
        case .graphQL: entries.filter { $0.source == .graphQL }
        }
    }

    @ObservationIgnored private let updates: @Sendable () -> AsyncStream<[NetworkLogEntry]>
    @ObservationIgnored private let clearLog: @Sendable () async -> Void

    /// - Parameters:
    ///   - updates: Snapshots of the whole log, oldest first, the current one immediately.
    ///   - clear: Empties the underlying log.
    public init(
        updates: @escaping @Sendable () -> AsyncStream<[NetworkLogEntry]>,
        clear: @escaping @Sendable () async -> Void
    ) {
        self.updates = updates
        self.clearLog = clear
    }

    /// Call this from `.task`. It updates `entries` live until the task is cancelled (the view disappears).
    public func observe() async {
        for await snapshot in updates() {
            entries = snapshot.reversed()
        }
    }

    public func clear() async {
        await clearLog()
    }

    /// The visible requests in the last `window`, for the "Last 10 s: 2 requests · 422 ms" header.
    public func summary(window: Duration = .seconds(10), now: Date = .now) -> Summary {
        let seconds = Double(window.components.seconds) + Double(window.components.attoseconds) / 1e18
        let since = now.addingTimeInterval(-seconds)
        let recent = visibleEntries.filter { $0.timestamp >= since }
        return Summary(requests: recent.count, totalDuration: recent.reduce(.zero) { $0 + $1.duration })
    }
}
