import Domain
import Testing

@Suite("SearchCastUseCase")
struct SearchCastUseCaseTests {
    @Test(
        "Normalizes the name filter",
        arguments: [
            (input: "   ", expected: nil),
            (input: "", expected: nil),
            (input: "\n\t ", expected: nil),
            (input: " rick ", expected: "rick"),
            (input: "rick", expected: "rick"),
            (input: "  Mr. Poopybutthole\n", expected: "Mr. Poopybutthole"),
        ] as [(input: String, expected: String?)])
    func normalizesName(input: String, expected: String?) async throws {
        let repository = StubCastRepository()
        let sut = SearchCastUseCase(repository: repository)

        _ = try await sut(filter: CastFilter(name: input))

        let call = try #require(await repository.castCalls.first)
        #expect(call.filter.name == expected)
    }

    @Test("A nil name stays nil")
    func nilNameStaysNil() async throws {
        let repository = StubCastRepository()
        let sut = SearchCastUseCase(repository: repository)

        _ = try await sut(filter: CastFilter())

        let call = try #require(await repository.castCalls.first)
        #expect(call.filter.name == nil)
    }

    @Test("Passes the status filter through unchanged", arguments: [nil] + CastMember.Status.allCases.map(Optional.some))
    func passesStatusThrough(status: CastMember.Status?) async throws {
        let repository = StubCastRepository()
        let sut = SearchCastUseCase(repository: repository)

        _ = try await sut(filter: CastFilter(name: " rick ", status: status))

        let call = try #require(await repository.castCalls.first)
        #expect(call.filter.status == status)
    }

    @Test("Defaults to page 1 and forwards explicit pages")
    func forwardsPage() async throws {
        let repository = StubCastRepository()
        let sut = SearchCastUseCase(repository: repository)

        _ = try await sut(filter: CastFilter())
        _ = try await sut(filter: CastFilter(), page: 3)

        #expect(await repository.castCalls.map(\.page) == [1, 3])
    }

    @Test("Returns the repository's page unchanged")
    func returnsPage() async throws {
        let page = Page(items: [CastMember.fixture()], nextPage: 2)
        let sut = SearchCastUseCase(repository: StubCastRepository(castResult: .success(page)))

        let result = try await sut(filter: CastFilter())

        #expect(result == page)
        #expect(result.hasMore)
    }

    @Test("Rethrows the repository's DomainError unchanged")
    func rethrowsError() async {
        let sut = SearchCastUseCase(repository: StubCastRepository(castResult: .failure(.offline)))

        await #expect(throws: DomainError.offline) {
            try await sut(filter: CastFilter(name: "rick"))
        }
    }
}
