import Domain

/// The full-screen state of a paginated list.
public enum ListPhase: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case empty
    case failed(DomainError)
}

/// The state of the "load more" footer of a paginated list.
public enum PaginationPhase: Equatable, Sendable {
    case idle
    case loading
    case failed(DomainError)
    case exhausted
}
