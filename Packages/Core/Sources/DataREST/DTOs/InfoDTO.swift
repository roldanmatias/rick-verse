import Foundation

/// Pagination metadata. `next` and `prev` are **full URLs**, not page numbers.
public struct InfoDTO: Decodable, Sendable {
    public let count: Int
    public let pages: Int
    public let next: URL?
    public let prev: URL?
}
