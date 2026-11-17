import Foundation

/// Mirrors `GET /character/{id}` exactly. Mapping to `CastMember` happens in `CharacterMapper`.
public struct CharacterDTO: Decodable, Sendable {
    /// A reference to a location.
    ///
    /// `url` is a `String`, not a `URL`, because the API sends `""` when the location is unknown
    /// (for example `{"name": "unknown", "url": ""}`). Decoding `""` as `URL` would throw and fail
    /// the whole page.
    public struct LocationRefDTO: Decodable, Sendable {
        public let name: String
        public let url: String
    }

    public let id: Int
    public let name: String
    /// The raw value: `"Alive"`, `"Dead"` or `"unknown"`. The case is inconsistent, so it's kept as a String here.
    public let status: String
    public let species: String
    /// A subspecies, often `""`.
    public let type: String
    public let gender: String
    public let origin: LocationRefDTO
    public let location: LocationRefDTO
    public let image: URL
    /// URLs of the episodes the character appears in, not episode objects.
    public let episode: [URL]
    public let url: URL
    public let created: Date
}
