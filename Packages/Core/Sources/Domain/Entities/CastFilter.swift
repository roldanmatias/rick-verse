/// Search criteria for the cast list. A `nil` field means "don't filter on this".
public struct CastFilter: Equatable, Sendable {
    public var name: String?
    public var status: CastMember.Status?

    public init(name: String? = nil, status: CastMember.Status? = nil) {
        self.name = name
        self.status = status
    }
}
