// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct CastPageQuery: GraphQLQuery {
    static let operationName: String = "CastPage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CastPage($page: Int!, $filter: FilterCharacter) { characters(page: $page, filter: $filter) { __typename info { __typename next } results { __typename ...CastMemberBasic } } }"#,
        fragments: [CastMemberBasic.self]
      ))

    public var page: Int32
    public var filter: GraphQLNullable<FilterCharacter>

    public init(
      page: Int32,
      filter: GraphQLNullable<FilterCharacter>
    ) {
      self.page = page
      self.filter = filter
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "page": page,
      "filter": filter
    ] }

    nonisolated struct Data: RickAndMortyAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("characters", Characters?.self, arguments: [
          "page": .variable("page"),
          "filter": .variable("filter")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CastPageQuery.Data.self
      ] }

      /// Get the list of all characters
      var characters: Characters? { __data["characters"] }

      /// Characters
      ///
      /// Parent Type: `Characters`
      nonisolated struct Characters: RickAndMortyAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Characters }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("info", Info?.self),
          .field("results", [Result?]?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CastPageQuery.Data.Characters.self
        ] }

        var info: Info? { __data["info"] }
        var results: [Result?]? { __data["results"] }

        /// Characters.Info
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
            CastPageQuery.Data.Characters.Info.self
          ] }

          /// Number of the next page (if it exists)
          var next: Int? { __data["next"] }
        }

        /// Characters.Result
        ///
        /// Parent Type: `Character`
        nonisolated struct Result: RickAndMortyAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { RickAndMortyAPI.Objects.Character }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(CastMemberBasic.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CastPageQuery.Data.Characters.Result.self,
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