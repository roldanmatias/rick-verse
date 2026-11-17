import Domain

extension PageDTO {
    func toDomain<Item: Sendable>(_ transform: (T) throws(DomainError) -> Item) throws(DomainError) -> Page<Item> {
        var items: [Item] = []
        items.reserveCapacity(results.count)
        for result in results {
            items.append(try transform(result))
        }
        return Page(items: items, nextPage: info.next?.pageQueryItem)
    }
}
