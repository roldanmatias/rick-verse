// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol RickAndMortyAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == RickAndMortyAPI.SchemaMetadata {}

nonisolated protocol RickAndMortyAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == RickAndMortyAPI.SchemaMetadata {}

nonisolated protocol RickAndMortyAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == RickAndMortyAPI.SchemaMetadata {}

nonisolated protocol RickAndMortyAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == RickAndMortyAPI.SchemaMetadata {}

extension RickAndMortyAPI {
  typealias SelectionSet = RickAndMortyAPI_SelectionSet

  typealias InlineFragment = RickAndMortyAPI_InlineFragment

  typealias MutableSelectionSet = RickAndMortyAPI_MutableSelectionSet

  typealias MutableInlineFragment = RickAndMortyAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "Character": RickAndMortyAPI.Objects.Character,
      "Characters": RickAndMortyAPI.Objects.Characters,
      "Episode": RickAndMortyAPI.Objects.Episode,
      "Episodes": RickAndMortyAPI.Objects.Episodes,
      "Info": RickAndMortyAPI.Objects.Info,
      "Location": RickAndMortyAPI.Objects.Location,
      "Query": RickAndMortyAPI.Objects.Query
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}