import Foundation

/// Mirrors `GET /episode/{id}`. The JSON's naming is kept out of the rest of the code with `CodingKeys`.
public struct EpisodeDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    /// A human-readable string such as `"December 2, 2013"`, not ISO 8601.
    public let airDate: String
    /// The broadcast code, for example `"S01E01"`. The JSON calls it `episode`.
    public let code: String
    public let characters: [URL]
    public let url: URL
    public let created: Date

    enum CodingKeys: String, CodingKey {
        case id, name, characters, url, created
        case airDate = "air_date"
        case code = "episode"
    }
}
