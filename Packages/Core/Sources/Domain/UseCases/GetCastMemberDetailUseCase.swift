/// Loads one cast member with their episodes.
public struct GetCastMemberDetailUseCase: Sendable {
    private let repository: any CastRepository

    public init(repository: any CastRepository) {
        self.repository = repository
    }

    public func callAsFunction(id: Int) async throws(DomainError) -> CastMemberDetail {
        try await repository.detail(id: id)
    }

    /// Cached value first (if any), then the fresh one. See ``CastRepository/detailUpdates(id:)``.
    public func updates(id: Int) -> AsyncThrowingStream<CastMemberDetail, any Error> {
        repository.detailUpdates(id: id)
    }
}
