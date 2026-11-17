import Foundation
import Testing

@testable import DataREST

struct URLHelpersTests {
    @Test(arguments: [
        ("https://rickandmortyapi.com/api/episode/28", 28),
        ("https://rickandmortyapi.com/api/character/1", 1),
        ("https://rickandmortyapi.com/api/episode/28/", 28),
    ])
    func trailingID(url: String, expected: Int) {
        #expect(URL(string: url)!.trailingID == expected)
    }

    @Test func nonNumericTrailingIDIsNil() {
        #expect(URL(string: "https://rickandmortyapi.com/api/episode")!.trailingID == nil)
    }

    @Test(arguments: [
        ("https://rickandmortyapi.com/api/character?page=2", 2),
        ("https://rickandmortyapi.com/api/character?page=2&name=rick&status=alive", 2),
        ("https://rickandmortyapi.com/api/character?name=rick&page=15", 15),
    ])
    func pageQueryItem(url: String, expected: Int) {
        #expect(URL(string: url)!.pageQueryItem == expected)
    }

    @Test(arguments: [
        "https://rickandmortyapi.com/api/character",
        "https://rickandmortyapi.com/api/character?name=rick",
        "https://rickandmortyapi.com/api/character?page=two",
    ])
    func missingPageIsNil(url: String) {
        #expect(URL(string: url)!.pageQueryItem == nil)
    }
}
