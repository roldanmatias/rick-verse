// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension RickAndMortyAPI {
  nonisolated struct FilterCharacter: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: GraphQLNullable<String> = nil,
      status: GraphQLNullable<String> = nil,
      species: GraphQLNullable<String> = nil,
      type: GraphQLNullable<String> = nil,
      gender: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "status": status,
        "species": species,
        "type": type,
        "gender": gender
      ])
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var status: GraphQLNullable<String> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    var species: GraphQLNullable<String> {
      get { __data["species"] }
      set { __data["species"] = newValue }
    }

    var type: GraphQLNullable<String> {
      get { __data["type"] }
      set { __data["type"] = newValue }
    }

    var gender: GraphQLNullable<String> {
      get { __data["gender"] }
      set { __data["gender"] = newValue }
    }
  }

}