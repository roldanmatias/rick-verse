import Domain
import Foundation

extension EpisodeDTO {
    func toDomain() throws(DomainError) -> Episode {
        guard let (season, number) = EpisodeCode.parse(code) else { throw .invalidData }
        return Episode(
            id: id, name: name, code: code,
            season: season, number: number,
            airDate: AirDate.parse(airDate)
        )
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

    static func parse(_ string: String) -> Date? {
        try? Date(string, strategy: strategy)
    }
}
