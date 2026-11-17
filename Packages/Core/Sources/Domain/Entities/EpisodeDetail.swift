/// Everything the episode detail screen shows: the episode plus its cast.
public struct EpisodeDetail: Identifiable, Hashable, Sendable {
    public let episode: Episode
    public let cast: [CastMember]

    public var id: Episode.ID { episode.id }

    public init(episode: Episode, cast: [CastMember]) {
        self.episode = episode
        self.cast = cast
    }
}
