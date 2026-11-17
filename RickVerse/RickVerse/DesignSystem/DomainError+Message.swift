import Domain

struct ErrorMessage {
    let title: String
    let message: String
    let systemImage: String
}

extension DomainError {
    var userMessage: ErrorMessage {
        switch self {
        case .offline:
            ErrorMessage(
                title: "You're offline",
                message: "Check your connection and try again.",
                systemImage: "wifi.slash")
        case .timeout:
            ErrorMessage(
                title: "That took too long",
                message: "The server didn't answer in time. Try again.",
                systemImage: "clock.badge.exclamationmark")
        case .notFound:
            ErrorMessage(
                title: "Not found",
                message: "This doesn't exist in any dimension we know of.",
                systemImage: "questionmark.folder")
        case .server:
            ErrorMessage(
                title: "Server problem",
                message: "Something broke on their side. Try again in a moment.",
                systemImage: "exclamationmark.icloud")
        case .invalidData:
            ErrorMessage(
                title: "Unexpected data",
                message: "The server sent something we couldn't read.",
                systemImage: "doc.badge.ellipsis")
        case .cancelled, .unknown:
            ErrorMessage(
                title: "Something went wrong",
                message: "Please try again.",
                systemImage: "exclamationmark.triangle")
        }
    }
}
