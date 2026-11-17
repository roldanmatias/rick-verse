import Domain
import Foundation
import Networking
import Testing

@testable import DataREST

struct ErrorMapperTests {
    @Test(arguments: [
        (NetworkError.offline, DomainError.offline),
        (.timeout, .timeout),
        (.cancelled, .cancelled),
        (.http(status: 404, body: Data()), .notFound),
        (.http(status: 408, body: Data()), .timeout),
        (.http(status: 429, body: Data()), .server),
        (.http(status: 500, body: Data()), .server),
        (.http(status: 503, body: Data()), .server),
        (.http(status: 400, body: Data()), .unknown),
        (.http(status: 401, body: Data()), .unknown),
        (.decoding("keyNotFound"), .invalidData),
        (.transport("TLS"), .unknown),
        (.invalidRequest, .unknown),
    ])
    func maps(network: NetworkError, expected: DomainError) {
        #expect(DomainError(network) == expected)
    }
}
