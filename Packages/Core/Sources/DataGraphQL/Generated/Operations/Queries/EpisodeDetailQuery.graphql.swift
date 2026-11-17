// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct EpisodeDetailQuery: GraphQLQuery {
    static let operationName: String = "EpisodeDetail"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EpisodeDetail($id: ID!) { episode(id: $id) { __typename ...EpisodeBasic characters { __typename ...CastMemberBasic } } }"#,
        fragments: [CastMemberBasic.self, EpisodeBasic.self]
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    nonisolated struct Data: RickAndMortyAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("episode", Episode?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EpisodeDetailQuery.Data.self
      ] }

      /// Get a specific episode by ID
      var episode: Episode? { __data["episode"] }

      /// Episode
      ///
      /// Parent Type: `Episode`
      nonisolated struct Episode: RickAndMortyAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Episode }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("characters", [Character?].self),
          .fragment(EpisodeBasic.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EpisodeDetailQuery.Data.Episode.self,
          EpisodeBasic.self
        ] }

        /// List of characters who have been seen in the episode.
        var characters: [Character?] { __data["characters"] }
        /// The id of the episode.
        var id: RickAndMortyAPI.ID? { __data["id"] }
        /// The name of the episode.
        var name: String? { __data["name"] }
        /// The code of the episode.
        var episode: String? { __data["episode"] }
        /// The air date of the episode.
        var air_date: String? { __data["air_date"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var episodeBasic: EpisodeBasic { _toFragment() }
        }

        /// Episode.Character
        ///
        /// Parent Type: `Character`
        nonisolated struct Character: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Character }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(CastMemberBasic.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EpisodeDetailQuery.Data.Episode.Character.self,
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

          struct Fragments: FragmentContainer {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            var castMemberBasic: CastMemberBasic { _toFragment() }
          }
        }
      }
    }
  }

}