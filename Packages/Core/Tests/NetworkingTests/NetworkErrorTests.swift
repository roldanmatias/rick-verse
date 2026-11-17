import Foundation
import Networking
import Testing

struct NetworkErrorTests {
    @Test(arguments: [
        (URLError.Code.cancelled, NetworkError.cancelled),
        (.notConnectedToInternet, .offline),
        (.networkConnectionLost, .offline),
        (.dataNotAllowed, .offline),
        (.timedOut, .timeout),
    ])
    func mapsURLErrors(code: URLError.Code, expected: NetworkError) {
        #expect(NetworkError(URLError(code)) == expected)
    }

    @Test func mapsOtherURLErrorsToTransport() {
        guard case .transport = NetworkError(URLError(.secureConnectionFailed)) else {
            Issue.record("Expected .transport")
            return
        }
    }

    @Test func mapsCancellationError() {
        #expect(NetworkError(CancellationError()) == .cancelled)
    }

    @Test func passesNetworkErrorThrough() {
        #expect(NetworkError(NetworkError.http(status: 418, body: Data())) == .http(status: 418, body: Data()))
    }

    @Test func mapsDecodingErrorWithKeyPath() throws {
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Hero.self, from: Data(#"{"id": 1}"#.utf8))
        }
        guard case let .decoding(message) = NetworkError(try #require(error)) else {
            Issue.record("Expected .decoding")
            return
        }
        #expect(message.contains("name"))
    }
}
