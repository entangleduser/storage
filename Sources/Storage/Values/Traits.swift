@_exported @testable import Composite
/// The traits of a `Content` structure that are used to change
/// the way values are collected
struct Traits: KeyValues {
 var values: [String: Any] = .empty
 static var defaultValues: OrderedDictionary<String, Any> {
  [
   ObservableKey.description: ObservableKey.defaultValue,
   ContentTypeKey.description: ContentTypeKey.resolvedValue as Any,
   RecursiveKey.description: RecursiveKey.defaultValue,
   RemovalMethodKey.description: RemovalMethodKey.defaultValue,
   CreateMethodKey.description: CreateMethodKey.defaultValue,
   UTTypeKey.description: UTTypeKey.resolvedValue as Any
  ]
 }
}
