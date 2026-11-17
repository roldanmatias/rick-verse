import Foundation

/// One recorded request, shown in the in-app network log.
public struct NetworkEvent: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable {
        case rest
        case graphQL
    }

    public let id: UUID
    public let timestamp: Date
    public let source: Source
    /// A short description: `"GET /api/character"` for REST, the operation name for GraphQL.
    public let label: String
    /// The HTTP status, or `nil` if the request failed before a response arrived.
    public let status: Int?
    public let duration: Duration
    public let bytes: Int
    /// The request was cancelled by the caller (for example, a newer search replaced it). That isn't a failure.
    public let cancelled: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        source: Source,
        label: String,
        status: Int?,
        duration: Duration,
        bytes: Int,
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

/// A record of every request made through REST or GraphQL that both share.
///
/// REST writes through `MetricsMiddleware` and GraphQL through Apollo's `MetricsInterceptor`.
/// Screens observe it with ``updates()``.
public actor NetworkLog {
    public private(set) var events: [NetworkEvent] = []
    private let capacity: Int
    private var subscribers: [UUID: AsyncStream<[NetworkEvent]>.Continuation] = [:]

    /// - Parameter capacity: The oldest events are dropped beyond this count, so the log can't grow without bound.
    public init(capacity: Int = 500) {
        self.capacity = capacity
    }

    public func record(_ event: NetworkEvent) {
        events.append(event)
        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }
        broadcast()
    }

    public func clear() {
        events.removeAll()
        broadcast()
    }

    /// A stream of snapshots (oldest first). The current snapshot is yielded immediately, then a
    /// new one after every change. Only the latest snapshot is buffered: a slow consumer skips
    /// intermediate states instead of queueing them.
    public nonisolated func updates() -> AsyncStream<[NetworkEvent]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [NetworkEvent].self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.unsubscribe(id) }
        }
        Task { await self.subscribe(id, continuation) }
        return stream
    }

    private func subscribe(_ id: UUID, _ continuation: AsyncStream<[NetworkEvent]>.Continuation) {
        subscribers[id] = continuation
        continuation.yield(events)
    }

    private func unsubscribe(_ id: UUID) {
        subscribers[id] = nil
    }

    private func broadcast() {
        for continuation in subscribers.values {
            continuation.yield(events)
        }
    }
}
