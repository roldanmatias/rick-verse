// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct EpisodePageQuery: GraphQLQuery {
    static let operationName: String = "EpisodePage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EpisodePage($page: Int!) { episodes(page: $page) { __typename info { __typename next } results { __typename ...EpisodeBasic } } }"#,
        fragments: [EpisodeBasic.self]
      ))

    public var page: Int32

    public init(page: Int32) {
      self.page = page
    }

    @_spi(Unsafe) public var __variables: Variables? { ["page": page] }

    nonisolated struct Data: RickAndMortyAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("episodes", Episodes?.self, arguments: ["page": .variable("page")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EpisodePageQuery.Data.self
      ] }

      /// Get the list of all episodes
      var episodes: Episodes? { __data["episodes"] }

      /// Episodes
      ///
      /// Parent Type: `Episodes`
      nonisolated struct Episodes: RickAndMortyAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Episodes }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("info", Info?.self),
          .field("results", [Result?]?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EpisodePageQuery.Data.Episodes.self
        ] }

        var info: Info? { __data["info"] }
        var results: [Result?]? { __data["results"] }

        /// Episodes.Info
        ///
        /// Parent Type: `Info`
        nonisolated struct Info: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Info }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("next", Int?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EpisodePageQuery.Data.Episodes.Info.self
          ] }

          /// Number of the next page (if it exists)
          var next: Int? { __data["next"] }
        }

        /// Episodes.Result
        ///
        /// Parent Type: `Episode`
        nonisolated struct Result: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Episode }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(EpisodeBasic.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            EpisodePageQuery.Data.Episodes.Result.self,
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