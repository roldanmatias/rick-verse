enum GraphQLClientError: Error {
    case noData(errors: [String])

    case transport(any Error)
}
