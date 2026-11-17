import Foundation
import Networking
import Testing

struct EndpointTests {
    @Test func appendsPathToBaseURL() throws {
        let request = try Endpoint<Hero>(path: "episode/1,2,3").urlRequest(baseURL: baseURL)
        #expect(request.url?.absoluteString == "https://rickandmortyapi.com/api/episode/1,2,3")
        #expect(request.httpMethod == "GET")
    }

    @Test func percentEncodesQueryItems() throws {
        let endpoint = Endpoint<Hero>(
            path: "character",
            queryItems: [
                URLQueryItem(name: "page", value: "2"),
                URLQueryItem(name: "name", value: "Rick Sanchez"),
                URLQueryItem(name: "status", value: "alive"),
            ])
        let request = try endpoint.urlRequest(baseURL: baseURL)
        #expect(
            request.url?.absoluteString
                == "https://rickandmortyapi.com/api/character?page=2&name=Rick%20Sanchez&status=alive")
    }

    @Test("Encodes + so the server doesn't read it as a space")
    func encodesPlus() throws {
        let endpoint = Endpoint<Hero>(path: "character", queryItems: [URLQueryItem(name: "name", value: "C++ Rick")])
        let request = try endpoint.urlRequest(baseURL: baseURL)
        #expect(request.url?.query(percentEncoded: true) == "name=C%2B%2B%20Rick")
    }

    @Test func noQueryItemsMeansNoQuestionMark() throws {
        let request = try Endpoint<Hero>(path: "character").urlRequest(baseURL: baseURL)
        #expect(request.url?.absoluteString == "https://rickandmortyapi.com/api/character")
    }

    @Test func setsMethodHeadersAndBody() throws {
        let request = try Endpoint<Hero>(
            path: "character", method: .put, headers: ["X-Trace": "abc"], body: Data("{}".utf8)
        ).urlRequest(baseURL: baseURL)
        #expect(request.httpMethod == "PUT")
        #expect(request.value(forHTTPHeaderField: "X-Trace") == "abc")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == Data("{}".utf8))
    }

    @Test func keepsExplicitContentType() throws {
        let request = try Endpoint<Hero>(
            path: "upload", method: .post, headers: ["Content-Type": "text/plain"], body: Data("hi".utf8)
        ).urlRequest(baseURL: baseURL)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
    }
}
