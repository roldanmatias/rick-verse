import Foundation
import TestSupport
import Testing

let graphQLEndpoint = URL(string: "https://rickandmortyapi.com/graphql")!

func fixture(_ name: String) throws -> Data {
    try Fixture.data(name, in: .module)
}

func fixtureResult(_ name: String) throws -> StubResult {
    .response(status: 200, headers: ["Content-Type": "application/json"], body: try fixture(name))
}

func editedFixture(_ name: String, _ edit: (inout [String: Any]) -> Void) throws -> StubResult {
    var json = try JSONSerialization.jsonObject(with: fixture(name)) as! [String: Any]
    edit(&json)
    return .response(
        status: 200, headers: ["Content-Type": "application/json"],
        body: try JSONSerialization.data(withJSONObject: json))
}

func requestBody(_ request: URLRequest) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as! [String: Any]
}
