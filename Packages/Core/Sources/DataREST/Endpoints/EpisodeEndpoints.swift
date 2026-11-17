import Foundation
import Networking

/// The REST endpoints for episodes.
public enum EpisodeEndpoints {
    /// `GET /episode?page=1`. It returns 20 episodes per page.
    public static func list(page: Int) -> Endpoint<PageDTO<EpisodeDTO>> {
        Endpoint(path: "episode", queryItems: [URLQueryItem(name: "page", value: String(page))])
    }

    /// `GET /episode/{id}`.
    public static func byID(_ id: Int) -> Endpoint<EpisodeDTO> {
        Endpoint(path: "episode/\(id)")
    }

    /// `GET /episode/1,2,3`. It returns an array, or a single object when given one ID.
    ///
    /// - Precondition: `ids` isn't empty.
    public static func byIDs(_ ids: [Int]) -> Endpoint<OneOrMany<EpisodeDTO>> {
        precondition(!ids.isEmpty, "byIDs needs at least one ID")
        return Endpoint(path: "episode/" + ids.map(String.init).joined(separator: ","))
    }
}
