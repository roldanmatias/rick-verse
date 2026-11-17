/// One page of a paginated result.
///
/// REST returns `info.next` as a full URL and GraphQL returns `info.next` as an `Int`.
/// Both data layers reduce it to ``nextPage`` so pagination works the same way
/// whichever API is active.
public struct Page<Item: Sendable>: Sendable {
    public let items: [Item]
    /// The number of the next page, or `nil` if this is the last page.
    public let nextPage: Int?

    /// `true` while there are more pages to load.
    public var hasMore: Bool { nextPage != nil }

    public init(items: [Item], nextPage: Int?) {
        self.items = items
        self.nextPage = nextPage
    }
}

extension Page: Equatable where Item: Equatable {}
extension Page: Hashable where Item: Hashable {}
