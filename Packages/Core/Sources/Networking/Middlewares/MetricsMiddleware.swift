import Foundation

/// Records each request into a ``NetworkLog``, including failed requests.
///
/// Put it before ``RetryMiddleware`` in the array to record one event per logical call,
/// or after it to record every attempt.
public struct MetricsMiddleware: RequestMiddleware {
    private let log: NetworkLog

    public init(log: NetworkLog) {
        self.log = log
    }

    public func intercept(_ request: URLRequest, next: NextHandler) async throws -> (Data, HTTPURLResponse) {
        let label = "\(request.httpMethod ?? "GET") \(request.url?.path() ?? "?")"
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let (data, response) = try await next(request)
            await log.record(
                NetworkEvent(
                    source: .rest, label: label, status: response.statusCode,
                    duration: clock.now - start, bytes: data.count
                ))
            return (data, response)
        } catch {
            await log.record(
                NetworkEvent(
                    source: .rest, label: label, status: nil,
                    duration: clock.now - start, bytes: 0,
                    cancelled: NetworkError(error) == .cancelled
                ))
            throw error
        }
    }
}
