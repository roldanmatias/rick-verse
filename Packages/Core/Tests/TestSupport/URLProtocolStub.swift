import Foundation

public enum StubResult: Sendable {
    case response(status: Int, headers: [String: String] = [:], body: Data = Data())
    case failure(URLError)

    public static func json(_ string: String, status: Int = 200, headers: [String: String] = [:]) -> StubResult {
        .response(
            status: status, headers: headers.merging(["Content-Type": "application/json"]) { a, _ in a },
            body: Data(string.utf8))
    }

    public static func status(_ status: Int, headers: [String: String] = [:]) -> StubResult {
        .response(status: status, headers: headers)
    }
}

public final class StubbedSession: Sendable {
    public let session: URLSession
    private let id = UUID().uuidString

    public init(handler: @escaping @Sendable (URLRequest) -> StubResult) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        configuration.httpAdditionalHeaders = [URLProtocolStub.idHeader: id]
        session = URLSession(configuration: configuration)
        URLProtocolStub.registry.register(id: id, handler: handler)
    }

    public convenience init(_ results: StubResult...) {
        precondition(!results.isEmpty, "Provide at least one StubResult")
        let queue = ResultQueue(results)
        self.init { _ in queue.next() }
    }

    public var requests: [URLRequest] {
        URLProtocolStub.registry.requests(id: id)
    }
}

public final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static let idHeader = "X-Stub-ID"
    static let registry = Registry()

    override public static func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: idHeader) != nil
    }

    override public static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        guard let id = request.value(forHTTPHeaderField: Self.idHeader),
            let handler = Self.registry.handler(id: id),
            let url = request.url
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        var recorded = request
        recorded.setValue(nil, forHTTPHeaderField: Self.idHeader)
        recorded.httpBody = request.httpBody ?? request.httpBodyStream.map(Self.readAll)
        Self.registry.record(recorded, id: id)

        switch handler(recorded) {
        case let .response(status, headers, body):
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }

        return data
    }

    final class Registry: @unchecked Sendable {
        private let lock = NSLock()
        private var handlers: [String: @Sendable (URLRequest) -> StubResult] = [:]
        private var log: [String: [URLRequest]] = [:]

        func register(id: String, handler: @escaping @Sendable (URLRequest) -> StubResult) {
            lock.withLock { handlers[id] = handler }
        }

        func handler(id: String) -> (@Sendable (URLRequest) -> StubResult)? {
            lock.withLock { handlers[id] }
        }

        func record(_ request: URLRequest, id: String) {
            lock.withLock { log[id, default: []].append(request) }
        }

        func requests(id: String) -> [URLRequest] {
            lock.withLock { log[id] ?? [] }
        }
    }
}

private final class ResultQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var results: [StubResult]

    init(_ results: [StubResult]) {
        self.results = results
    }

    func next() -> StubResult {
        lock.withLock { results.count > 1 ? results.removeFirst() : results[0] }
    }
}
