import Apollo
import ApolloAPI

struct ClientHeadersInterceptor: GraphQLInterceptor {
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        var request = request
        request.additionalHeaders["X-Client"] = "RickVerse-iOS"
        return await next(request)
    }
}
