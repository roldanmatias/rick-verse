import Domain

/// Episodes of one season, for sectioned lists.
///
/// It's a named type rather than a `(season: Int, episodes: [Episode])` tuple, so it can be
/// `Identifiable` (for `ForEach`) and `Equatable` (for tests).
public struct SeasonSection: Identifiable, Equatable, Sendable {
    public let season: Int
    public let episodes: [Episode]

    public var id: Int { season }

    public init(season: Int, episodes: [Episode]) {
        self.season = season
        self.episodes = episodes
    }

    /// Groups episodes by season. Seasons are sorted ascending, and episodes within a season by number.
    public static func group(_ episodes: [Episode]) -> [SeasonSection] {
        Dictionary(grouping: episodes, by: \.season)
            .sorted { $0.key < $1.key }
            .map { SeasonSection(season: $0.key, episodes: $0.value.sorted { $0.number < $1.number }) }
    }
}
