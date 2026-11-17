import Foundation
import Networking
import Testing

struct JSONDecoderTests {
    private struct Stamped: Decodable { let created: Date }

    @Test("Decodes the API's fractional-second dates exactly")
    func fractionalSeconds() throws {
        let json = Data(#"{"created": "2017-11-04T18:48:46.250Z"}"#.utf8)
        let date = try JSONDecoder.rickVerse.decode(Stamped.self, from: json).created
        #expect(date.timeIntervalSince1970 == 1_509_821_326.25)
    }

    @Test func wholeSeconds() throws {
        let json = Data(#"{"created": "2017-11-04T18:48:46Z"}"#.utf8)
        let date = try JSONDecoder.rickVerse.decode(Stamped.self, from: json).created
        #expect(date.timeIntervalSince1970 == 1_509_821_326)
    }

    @Test func rejectsGarbage() {
        let json = Data(#"{"created": "December 2, 2013"}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder.rickVerse.decode(Stamped.self, from: json) }
    }
}
