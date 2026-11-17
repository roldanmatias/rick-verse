import Foundation
import Networking

let baseURL = URL(string: "https://rickandmortyapi.com/api")!

struct Hero: Decodable, Sendable, Equatable {
    let id: Int
    let name: String
}

extension Endpoint where Response == Hero {
    static let hero = Endpoint(path: "character/1")
    static let createHero = Endpoint(path: "character", method: .post, body: Data(#"{"name":"Rick"}"#.utf8))
}

let heroJSON = #"{"id": 1, "name": "Rick Sanchez"}"#

func httpResponse(_ status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
    HTTPURLResponse(url: baseURL, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
}

func getRequest(_ method: HTTPMethod = .get) -> URLRequest {
    var request = URLRequest(url: baseURL.appending(path: "character"))
    request.httpMethod = method.rawValue
    return request
}

final class ScriptedNext: @unchecked Sendable {
    enum Step {
        case status(Int, headers: [String: String] = [:])
        case error(any Error)
    }

    private let lock = NSLock()
    private var steps: [Step]
    private var _calls = 0

    init(_ steps: Step...) { self.steps = steps }

    var calls: Int { lock.withLock { _calls } }

    var handler: NextHandler {
        { [self] _ in
            let step = lock.withLock { () -> Step in
                _calls += 1
                return steps.count > 1 ? steps.removeFirst() : steps[0]
            }
            switch step {
            case let .status(code, headers): return (Data(), httpResponse(code, headers: headers))
            case let .error(error): throw error
            }
        }
    }
}
