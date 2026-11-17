import Domain
import Networking

extension DomainError {
    init(_ error: NetworkError) {
        switch error {
        case .offline:
            self = .offline
        case .timeout, .http(status: 408, _):
            self = .timeout
        case .cancelled:
            self = .cancelled
        case .http(status: 404, _):
            self = .notFound
        case .http(status: 429, _), .http(status: 500...599, _):
            self = .server
        case .decoding:
            self = .invalidData
        case .invalidRequest, .http, .transport:
            self = .unknown
        }
    }
}

extension DomainError {
    init(any error: any Error) {
        switch error {
        case let error as DomainError: self = error
        case let error as NetworkError: self.init(error)
        case is CancellationError: self = .cancelled
        default: self = .unknown
        }
    }
}
