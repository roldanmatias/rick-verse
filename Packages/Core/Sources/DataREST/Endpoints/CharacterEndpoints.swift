import Domain
import Foundation
import Networking

/// The REST endpoints for characters.
public enum CharacterEndpoints {
    /// `GET /character?page=2&name=rick&status=alive`. It returns 20 characters per page.
    public static func list(page: Int, filter: CastFilter) -> Endpoint<PageDTO<CharacterDTO>> {
        var query = [URLQueryItem(name: "page", value: String(page))]
        if let name = filter.name {
            query.append(URLQueryItem(name: "name", value: name))
        }
        if let status = filter.status {
            query.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        return Endpoint(path: "character", queryItems: query)
    }

    /// `GET /character/{id}`.
    public static func byID(_ id: Int) -> Endpoint<CharacterDTO> {
        Endpoint(path: "character/\(id)")
    }

    /// `GET /character/1,2,3`. It returns an array, or a single object when given one ID.
    ///
    /// - Precondition: `ids` isn't empty. `GET /character/` returns the first *page*, which is a different shape.
    public static func byIDs(_ ids: [Int]) -> Endpoint<OneOrMany<CharacterDTO>> {
        precondition(!ids.isEmpty, "byIDs needs at least one ID")
        return Endpoint(path: "character/" + ids.map(String.init).joined(separator: ","))
    }
}
