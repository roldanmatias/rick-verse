import Domain

actor StubCastRepository: CastRepository {
    struct CastCall: Equatable {
        let page: Int
        let filter: CastFilter
    }

    private(set) var castCalls: [CastCall] = []
    private(set) var detailCalls: [Int] = []

    private let castResult: Result<Page<CastMember>, DomainError>
    private let detailResult: Result<CastMemberDetail, DomainError>

    init(
        castResult: Result<Page<CastMember>, DomainError> = .success(Page(items: [], nextPage: nil)),
        detailResult: Result<CastMemberDetail, DomainError> = .failure(.notFound)
    ) {
        self.castResult = castResult
        self.detailResult = detailResult
    }

    func cast(page: Int, filter: CastFilter) async throws(DomainError) -> Page<CastMember> {
        castCalls.append(CastCall(page: page, filter: filter))
        return try castResult.get()
    }

    func detail(id: Int) async throws(DomainError) -> CastMemberDetail {
        detailCalls.append(id)
        return try detailResult.get()
    }
}
