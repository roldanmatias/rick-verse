import Networking
import Testing

struct HTTPMethodTests {
    @Test(arguments: [
        (HTTPMethod.get, true), (.put, true), (.delete, true),
        (.post, false), (.patch, false),
    ])
    func idempotency(method: HTTPMethod, expected: Bool) {
        #expect(method.isIdempotent == expected)
    }
}
