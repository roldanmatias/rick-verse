import Foundation

nonisolated enum Route: Hashable {
    case castMember(id: Int)
    case episode(id: Int)

    static let scheme = "rickverse"

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
            let host = url.host()?.lowercased(),
            url.pathComponents.count == 2,
            let id = Int(url.lastPathComponent), id > 0
        else { return nil }

        switch host {
        case "character": self = .castMember(id: id)
        case "episode": self = .episode(id: id)
        default: return nil
        }
    }

    private static let characterBase = URL(string: "rickverse://character")!
    private static let episodeBase = URL(string: "rickverse://episode")!

    var url: URL {
        switch self {
        case let .castMember(id): Self.characterBase.appending(path: String(id))
        case let .episode(id): Self.episodeBase.appending(path: String(id))
        }
    }
}
