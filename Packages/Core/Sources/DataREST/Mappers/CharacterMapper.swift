import Domain

extension CharacterDTO {
    func toDomain() -> CastMember {
        CastMember(id: id, name: name, status: CastMember.Status(apiValue: status), species: species, imageURL: image)
    }
}

extension CastMember.Status {
    init(apiValue: String) {
        self = Self(rawValue: apiValue.lowercased()) ?? .unknown
    }
}
