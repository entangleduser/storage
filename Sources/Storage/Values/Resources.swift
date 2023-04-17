@_exported import Composite
/// The common attributes or file system metadata of a structure
public struct Resources: KeyValues {
 public init() {}
 public var values: [String: Any] = .empty
 public static var defaultValues: OrderedDictionary<String, Any> {
  [
   DirectoryKey.description: DirectoryKey.resolvedValue,
   HiddenKey.description: HiddenKey.resolvedValue,
   ExecutableKey.description: ExecutableKey.resolvedValue,
   URLFileResourceTypeKey.description:
    URLFileResourceTypeKey.resolvedValue as Any,
   TypeIdentifierKey.description: TypeIdentifierKey.resolvedValue as Any,
   TypeDescriptionKey.description: TypeDescriptionKey.resolvedValue as Any,
   TagNamesKey.description: TagNamesKey.resolvedValue as Any
  ]
 }
}

extension URLFileResourceType: CustomStringConvertible {
 public var description: String {
  switch self {
  case .regular: return "regular"
  case .directory: return "directory"
  case .blockSpecial: return "block special"
  case .characterSpecial: return "character special"
  case .namedPipe: return "name pipe"
  case .socket: return "socket"
  case .symbolicLink: return "symbolic link"
  default: return "unknown"
  }
 }
}
