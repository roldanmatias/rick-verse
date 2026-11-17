import Foundation
import Testing

@testable import DataREST

struct OneOrManyTests {
    @Test("A batch request returns an array, in order")
    func decodesArray() throws {
        let decoded = try decodeFixture(OneOrMany<EpisodeDTO>.self, "episodes_1_2_3")
        #expect(decoded.values.map(\.id) == [1, 2, 3])
    }

    @Test("A batch request with one ID returns a bare object")
    func decodesSingleObject() throws {
        let decoded = try decodeFixture(OneOrMany<EpisodeDTO>.self, "episode_1")
        #expect(decoded.values.map(\.id) == [1])
    }

    @Test func decodesEmptyArray() throws {
        let decoded = try JSONDecoder().decode(OneOrMany<Int>.self, from: Data("[]".utf8))
        #expect(decoded.values.isEmpty)
    }

    @Test func rejectsOtherShapes() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OneOrMany<EpisodeDTO>.self, from: Data(#"{"error": "nope"}"#.utf8))
        }
    }
}
