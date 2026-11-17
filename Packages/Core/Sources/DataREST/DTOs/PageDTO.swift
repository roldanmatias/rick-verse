/// The envelope every list endpoint returns: `{ "info": {...}, "results": [...] }`.
public struct PageDTO<T: Decodable & Sendable>: Decodable, Sendable {
    public let info: InfoDTO
    public let results: [T]
}
