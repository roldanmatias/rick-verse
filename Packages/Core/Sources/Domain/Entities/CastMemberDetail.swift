/// Everything the detail screen shows for one ``CastMember``.
///
/// It wraps the list entity instead of repeating its fields, so the list and detail
/// screens can never disagree about a character's name or status.
public struct CastMemberDetail: Identifiable, Hashable, Sendable {
    public let member: CastMember
    public let gender: String
    public let originName: String
    public let locationName: String
    /// Episodes the character appears in.
    public let episodes: [Episode]

    public var id: CastMember.ID { member.id }

    public init(
        member: CastMember,
        gender: String,
        originName: String,
        locationName: String,
        episodes: [Episode]
    ) {
        self.member = member
        self.gender = gender
        self.originName = originName
        self.locationName = locationName
        self.episodes = episodes
    }
}
