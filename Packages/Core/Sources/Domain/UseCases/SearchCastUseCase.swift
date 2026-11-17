import Foundation

/// Searches the cast and normalizes the filter before it reaches a repository.
///
/// It trims whitespace from the name and turns an empty name into `nil`, so repositories
/// never send `name=` or `name: "   "` to the server.
public struct SearchCastUseCase: Sendable {
    private let repository: any CastRepository

    public init(repository: any CastRepository) {
        self.repository = repository
    }

    public func callAsFunction(filter: CastFilter, page: Int = 1) async throws(DomainError) -> Page<CastMember> {
        var normalized = filter
        let trimmed = filter.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        normalized.name = trimmed.isEmpty ? nil : trimmed
        return try await repository.cast(page: page, filter: normalized)
    }
}
