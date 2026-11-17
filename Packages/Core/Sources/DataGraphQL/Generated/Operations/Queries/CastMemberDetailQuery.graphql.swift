// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct CastMemberDetailQuery: GraphQLQuery {
    static let operationName: String = "CastMemberDetail"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CastMemberDetail($id: ID!) { character(id: $id) { __typename ...CastMemberBasic gender origin { __typename id name } location { __typename id name } episode { __typename ...EpisodeBasic } } }"#,
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
        .field("character", Character?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CastMemberDetailQuery.Data.self
      ] }

      /// Get a specific character by ID
      var character: Character? { __data["character"] }

      /// Character
      ///
      /// Parent Type: `Character`
      nonisolated struct Character: RickAndMortyAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Character }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("gender", String?.self),
          .field("origin", Origin?.self),
          .field("location", Location?.self),
          .field("episode", [Episode?].self),
          .fragment(CastMemberBasic.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CastMemberDetailQuery.Data.Character.self,
          CastMemberBasic.self
        ] }

        /// The gender of the character ('Female', 'Male', 'Genderless' or 'unknown').
        var gender: String? { __data["gender"] }
        /// The character's origin location
        var origin: Origin? { __data["origin"] }
        /// The character's last known location
        var location: Location? { __data["location"] }
        /// Episodes in which this character appeared.
        var episode: [Episode?] { __data["episode"] }
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

        /// Character.Origin
        ///
        /// Parent Type: `Location`
        nonisolated struct Origin: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Location }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", RickAndMortyAPI.ID?.self),
            .field("name", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CastMemberDetailQuery.Data.Character.Origin.self
          ] }

          /// The id of the location.
          var id: RickAndMortyAPI.ID? { __data["id"] }
          /// The name of the location.
          var name: String? { __data["name"] }
        }

        /// Character.Location
        ///
        /// Parent Type: `Location`
        nonisolated struct Location: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Location }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", RickAndMortyAPI.ID?.self),
            .field("name", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CastMemberDetailQuery.Data.Character.Location.self
          ] }

          /// The id of the location.
          var id: RickAndMortyAPI.ID? { __data["id"] }
          /// The name of the location.
          var name: String? { __data["name"] }
        }

        /// Character.Episode
        ///
        /// Parent Type: `Episode`
        nonisolated struct Episode: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Episode }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(EpisodeBasic.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CastMemberDetailQuery.Data.Character.Episode.self,
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

          struct Fragments: FragmentContainer {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            var episodeBasic: EpisodeBasic { _toFragment() }
          }
        }
      }
    }
  }

}