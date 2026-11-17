extension Array {
    func ordered<ID: Hashable>(by ids: [ID], id: (Element) -> ID) -> [Element] {
        let byID = Dictionary(map { (id($0), $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }
}
