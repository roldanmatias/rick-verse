// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct CastMemberBasic: RickAndMortyAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment CastMemberBasic on Character { __typename id name status species image }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Character }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", RickAndMortyAPI.ID?.self),
      .field("name", String?.self),
      .field("status", String?.self),
      .field("species", String?.self),
      .field("image", String?.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CastMemberBasic.self
    ] }

    /// The id of the character.
    var id: RickAndMortyAPI.ID? { __data["id"] }
    /// The name of the character.
    var name: String? { __data["name"] }
    /// The status of the character ('Alive', 'Dead' or 'unknown').
    var status: String? { __data["status"] }
    /// The species of the character.
    var species: String? { __data["species"] }
    /// Link to the character's image.
    /// All images are 300x300px and most are medium shots or portraits since they are intended to be used as avatars.
    var image: String? { __data["image"] }
  }

}