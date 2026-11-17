import Domain
import Foundation

extension CastMember.Status {
    init(apiValue: String?) {
        self = apiValue.flatMap { Self(rawValue: $0.lowercased()) } ?? .unknown
    }
}

enum EpisodeCode {
    static func parse(_ code: String) -> (season: Int, number: Int)? {
        guard let match = code.wholeMatch(of: /S(\d+)E(\d+)/),
            let season = Int(match.1), let number = Int(match.2)
        else { return nil }
        return (season, number)
    }
}

enum AirDate {
    static let strategy = Date.ParseStrategy(
        format: "\(month: .wide) \(day: .defaultDigits), \(year: .defaultDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt,
        isLenient: false
    )

    static func parse(_ string: String?) -> Date? {
        string.flatMap { try? Date($0, strategy: strategy) }
    }
}
