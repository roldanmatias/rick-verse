import Foundation
import Networking
import Testing

struct LoggingMiddlewareTests {
    @Test func passesResponseThrough() async throws {
        let sent = Box<URLRequest?>(nil)
        let next: NextHandler = { request in
            sent.value = request
            return (Data("ok".utf8), httpResponse(201))
        }
        var request = getRequest()
        request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")

        let (data, response) = try await LoggingMiddleware().intercept(request, next: next)

        #expect(data == Data("ok".utf8))
        #expect(response.statusCode == 201)
        #expect(sent.value == request)
    }

    @Test func rethrowsErrors() async {
        let next: NextHandler = { _ in throw URLError(.timedOut) }
        await #expect(throws: URLError(.timedOut)) {
            try await LoggingMiddleware().intercept(getRequest(), next: next)
        }
    }
}

final class Box<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value
    init(_ value: Value) { _value = value }
    var value: Value {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}
