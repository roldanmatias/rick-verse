/// Declares the cast data the Domain needs. It says *what*, and each data layer decides *how*.
///
/// `DataREST` and `DataGraphQL` each provide a conforming type, and the app picks one at runtime.
public protocol CastRepository: Sendable {
    /// Fetches one page of cast members that match `filter`.
    /// - Parameters:
    ///   - page: The 1-based page number.
    ///   - filter: The criteria to apply. They're already normalized by ``SearchCastUseCase``.
    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember>

    /// Fetches one cast member with their episodes.
    func detail(id: Int) async throws(DomainError) -> CastMemberDetail

    /// Stale-while-revalidate: yields a cached detail first, if one exists, and then the fresh one.
    ///
    /// The default implementation yields ``detail(id:)`` once, which is what REST does. A data
    /// source with a normalized cache (GraphQL) overrides it to yield twice. Errors thrown by the
    /// stream are always `DomainError`. `AsyncThrowingStream` can't carry a typed failure yet.
    func detailUpdates(id: Int) -> AsyncThrowingStream<CastMemberDetail, any Error>
}

extension CastRepository {
    public func detailUpdates(id: Int) -> AsyncThrowingStream<CastMemberDetail, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try await detail(id: id))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
