import Apollo
import Foundation
import Networking

struct MetricsInterceptor: HTTPInterceptor {
    let log: NetworkLog
    let operationName: String

    func intercept(request: URLRequest, next: NextHTTPInterceptorFunction) async throws -> HTTPResponse {
        let clock = ContinuousClock()
        let start = clock.now
        let response: HTTPResponse
        do {
            response = try await next(request)
        } catch {
            await log.record(
                NetworkEvent(
                    source: .graphQL, label: operationName, status: nil,
                    duration: clock.now - start, bytes: 0,
                    cancelled: NetworkError(error) == .cancelled))
            throw error
        }

        let log = self.log
        let label = operationName
        return await response.mapChunks { httpResponse, chunk in
            await log.record(
                NetworkEvent(
                    source: .graphQL, label: label, status: httpResponse.statusCode,
                    duration: clock.now - start, bytes: chunk.count))
            return chunk
        }
    }
}
