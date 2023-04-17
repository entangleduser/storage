@_exported import Composite
public struct Attributes: KeyValues {
 public init() {}
 public var values: [String: Any] = .empty
 public static var defaultValues: OrderedDictionary<String, Any> {
  [
   PathKey.description: PathKey.resolvedValue as Any,
   NameKey.description: NameKey.defaultValue,
   ExtensionKey.description: ExtensionKey.resolvedValue as Any,
   FileNumberKey.description: FileNumberKey.resolvedValue as Any,
   FilePermissionsKey.description: FilePermissionsKey.resolvedValue,
   FileSizeKey.description: FileSizeKey.defaultValue,
   ExtensionHiddenKey.description: ExtensionHiddenKey.resolvedValue as Any,
   DateCreatedKey.description: DateCreatedKey.resolvedValue as Any,
   DateModifiedKey.description: DateModifiedKey.resolvedValue as Any,
   DateAddedKey.description: DateAddedKey.resolvedValue as Any
  ]
 }
}

public extension DynamicContent {
 typealias Attribute<Value> = AttributeProperty<Value, Self>
}
