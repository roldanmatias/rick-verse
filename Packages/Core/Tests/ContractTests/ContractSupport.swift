import Foundation
import Testing

let contractTestsEnabled = ProcessInfo.processInfo.environment["RUN_CONTRACT_TESTS"] == "1"

let restBase = URL(string: "https://rickandmortyapi.com/api")!
let graphQLEndpoint = URL(string: "https://rickandmortyapi.com/graphql")!

func rawGET(_ path: String) async throws -> (status: Int, json: Any) {
    let (data, response) = try await URLSession.shared.data(from: URL(string: restBase.absoluteString + "/" + path)!)
    let status = try #require(response as? HTTPURLResponse).statusCode
    return (status, try JSONSerialization.jsonObject(with: data))
}

func rawGraphQL(_ query: String) async throws -> [String: Any] {
    var request = URLRequest(url: graphQLEndpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
    let (data, response) = try await URLSession.shared.data(for: request)
    #expect((response as? HTTPURLResponse)?.statusCode == 200)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
}
