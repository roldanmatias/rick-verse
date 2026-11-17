// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct EpisodeBasic: RickAndMortyAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment EpisodeBasic on Episode { __typename id name episode air_date }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Episode }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", RickAndMortyAPI.ID?.self),
      .field("name", String?.self),
      .field("episode", String?.self),
      .field("air_date", String?.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      EpisodeBasic.self
    ] }

    /// The id of the episode.
    var id: RickAndMortyAPI.ID? { __data["id"] }
    /// The name of the episode.
    var name: String? { __data["name"] }
    /// The code of the episode.
    var episode: String? { __data["episode"] }
    /// The air date of the episode.
    var air_date: String? { __data["air_date"] }
  }

}