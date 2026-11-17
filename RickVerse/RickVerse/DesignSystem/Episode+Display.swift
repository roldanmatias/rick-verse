import Domain
import Foundation

extension Episode {
    func airDateText(_ style: Date.FormatStyle.DateStyle = .abbreviated) -> String? {
        airDate?.formatted(Date.FormatStyle(date: style, time: .omitted, timeZone: .gmt))
    }
}
