// @generated
// This file was automatically generated and can be edited to
// provide custom configuration for a generated GraphQL schema.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import ApolloAPI

/// Cache keys for Apollo's normalized cache.
///
/// The guide's `@typePolicy(keyFields: "id")` doesn't work with this schema. Codegen rejects it
/// because key fields must be non-null, and here every `id` is nullable (`id: ID`). So keys are
/// resolved in code instead:
/// - `Character`, `Episode` and `Location` with an `id` → `Character:1`, `Episode:28`, …
///   Each entity is stored once, however many queries fetch it.
/// - A `null` ID, or any other type → `nil`, and Apollo falls back to a path-based key
///   (for example `QUERY_ROOT.characters(page:1).results.0`), which is never shared across queries.
///
/// Every selection that includes these types must select `id` (the fragments do).
nonisolated enum SchemaConfiguration: ApolloAPI.SchemaConfiguration {
  static func cacheKeyInfo(for type: ApolloAPI.Object, object: ApolloAPI.ObjectData) -> CacheKeyInfo? {
    switch type {
    case RickAndMortyAPI.Objects.Character, RickAndMortyAPI.Objects.Episode, RickAndMortyAPI.Objects.Location:
      // The type name is prepended automatically (`uniqueKeyGroup` is nil), so IDs can't collide across types.
      return try? CacheKeyInfo(jsonValue: object["id"])
    default:
      return nil
    }
  }
}
