import Foundation

extension JSONDecoder {
    /// The decoder every REST call uses.
    ///
    /// The API sends dates like `2017-11-04T18:48:46.250Z`. The built-in `.iso8601` strategy
    /// rejects fractional seconds, so this strategy tries a fractional format first and then
    /// falls back to the plain one.
    public static var rickVerse: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
                return date
            }
            if let date = try? Date.ISO8601FormatStyle().parse(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO 8601 date, got \"\(string)\""
            )
        }
        return decoder
    }
}
