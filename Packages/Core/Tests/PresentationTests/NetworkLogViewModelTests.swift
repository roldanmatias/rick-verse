import Foundation
import Testing

@testable import Presentation

@MainActor
struct NetworkLogViewModelTests {
    nonisolated private static func entry(
        _ source: NetworkLogEntry.Source, _ label: String, ago seconds: TimeInterval = 0,
        ms: Int = 100, now: Date = Date(timeIntervalSince1970: 1_000)
    ) -> NetworkLogEntry {
        NetworkLogEntry(
            id: UUID(), timestamp: now.addingTimeInterval(-seconds), source: source, label: label,
            status: 200, duration: .milliseconds(ms), bytes: 10)
    }

    private func makeSUT(_ snapshots: [[NetworkLogEntry]], cleared: Counter = Counter()) -> NetworkLogViewModel {
        NetworkLogViewModel(
            updates: {
                AsyncStream { continuation in
                    for snapshot in snapshots {
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                }
            },
            clear: { _ = await cleared.increment() }
        )
    }

    @Test("Shows the latest snapshot, newest first")
    func newestFirst() async {
        let a = Self.entry(.rest, "GET /character/1")
        let b = Self.entry(.graphQL, "CastMemberDetail")
        let sut = makeSUT([[a], [a, b]])

        await sut.observe()

        #expect(sut.entries.map(\.label) == ["CastMemberDetail", "GET /character/1"])
    }

    @Test(arguments: [
        (NetworkLogViewModel.SourceFilter.all, 3),
        (.rest, 2),
        (.graphQL, 1),
    ])
    func filters(filter: NetworkLogViewModel.SourceFilter, expected: Int) async {
        let sut = makeSUT([[Self.entry(.rest, "a"), Self.entry(.graphQL, "b"), Self.entry(.rest, "c")]])
        await sut.observe()
        sut.filter = filter
        #expect(sut.visibleEntries.count == expected)
    }

    @Test("Summary counts only the visible requests in the window")
    func summary() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = [
            Self.entry(.rest, "old", ago: 30, ms: 999, now: now),
            Self.entry(.rest, "a", ago: 5, ms: 200, now: now),
            Self.entry(.graphQL, "b", ago: 1, ms: 222, now: now),
        ]
        let sut = makeSUT([snapshot])
        await sut.observe()

        #expect(sut.summary(now: now) == .init(requests: 2, totalDuration: .milliseconds(422)))
        sut.filter = .graphQL
        #expect(sut.summary(now: now) == .init(requests: 1, totalDuration: .milliseconds(222)))
    }

    @Test("clear() calls the log's clear exactly once")
    func clearCallsTheLog() async {
        await confirmation(expectedCount: 1) { confirm in
            let sut = NetworkLogViewModel(updates: { AsyncStream { $0.finish() } }, clear: { confirm() })
            await sut.clear()
        }
    }
}
