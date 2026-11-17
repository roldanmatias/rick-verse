import Foundation

/// One episode of the show.
public struct Episode: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    /// The broadcast code, for example `"S01E01"`.
    public let code: String
    public let season: Int
    public let number: Int
    /// When the episode first aired. It's `nil` if the server sends a date the Data layer can't parse.
    public let airDate: Date?

    public init(id: Int, name: String, code: String, season: Int, number: Int, airDate: Date?) {
        self.id = id
        self.name = name
        self.code = code
        self.season = season
        self.number = number
        self.airDate = airDate
    }
}
