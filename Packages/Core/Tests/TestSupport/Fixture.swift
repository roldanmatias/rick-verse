import Foundation

public enum Fixture {
    public struct NotFound: Error, CustomStringConvertible {
        public let name: String
        public var description: String { "Fixture \(name).json isn't in the test bundle. Is it under Fixtures/?" }
    }

    public static func data(_ name: String, in bundle: Bundle) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NotFound(name: name)
        }
        return try Data(contentsOf: url)
    }

    public struct NotUTF8: Error {
        public let name: String
    }

    public static func string(_ name: String, in bundle: Bundle) throws -> String {
        guard let string = String(bytes: try data(name, in: bundle), encoding: .utf8) else { throw NotUTF8(name: name) }
        return string
    }
}
