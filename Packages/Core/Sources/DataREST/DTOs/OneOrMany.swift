/// Decodes either a JSON array or a single object into an array.
///
/// The batch endpoints (`/episode/1,2,3`) return an array, but with one ID (`/episode/1`)
/// they return a bare object. Rather than special-casing the request, this type accepts
/// both shapes.
public struct OneOrMany<T: Decodable & Sendable>: Decodable, Sendable {
    public let values: [T]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([T].self) {
            values = array
        } else {
            values = [try container.decode(T.self)]
        }
    }
}
