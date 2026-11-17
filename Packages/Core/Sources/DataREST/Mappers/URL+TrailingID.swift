import Foundation

extension URL {
    var trailingID: Int? {
        Int(lastPathComponent)
    }

    var pageQueryItem: Int? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "page" }?
            .value
            .flatMap(Int.init)
    }
}
