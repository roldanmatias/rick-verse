import Foundation

/// A character from the show, as the app reasons about it.
///
/// This is the single shape both data layers map to. The REST `CharacterDTO` and the
/// GraphQL-generated selection set look different on the wire, but both end up here.
///
/// > Note: It's deliberately not called `Character`, because that would shadow `Swift.Character`.
public struct CastMember: Identifiable, Hashable, Sendable {
    /// Whether the character is alive in the show's canon.
    public enum Status: String, CaseIterable, Sendable {
        case alive
        case dead
        case unknown
    }

    public let id: Int
    public let name: String
    public let status: Status
    public let species: String
    public let imageURL: URL

    public init(id: Int, name: String, status: Status, species: String, imageURL: URL) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.imageURL = imageURL
    }
}
