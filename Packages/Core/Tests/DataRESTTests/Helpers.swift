import Foundation
import Networking
import TestSupport

let baseURL = URL(string: "https://rickandmortyapi.com/api")!

func fixture(_ name: String) throws -> Data {
    try Fixture.data(name, in: .module)
}

func decodeFixture<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
    try JSONDecoder.rickVerse.decode(T.self, from: fixture(name))
}

func makeClient(_ stub: StubbedSession) -> URLSessionHTTPClient {
    URLSessionHTTPClient(baseURL: baseURL, session: stub.session)
}

func fixtureResult(_ name: String, status: Int = 200) throws -> StubResult {
    .response(status: status, headers: ["Content-Type": "application/json"], body: try fixture(name))
}
