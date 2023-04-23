@_exported import Composite
public protocol ResourcesKey: ResolvedKey {}

public struct DirectoryKey: ResourcesKey, IntBoolKey {}

public struct HiddenKey: ResourcesKey, IntBoolKey {}

public struct ExecutableKey: ResourcesKey, IntBoolKey {}

public struct URLFileResourceTypeKey: ResourcesKey, OptionalKey {
 public typealias Value = URLFileResourceType
}

@_exported import UniformTypeIdentifiers
public struct TypeIdentifierKey: ResourcesKey, OptionalKey {
 public typealias Value = UTType
}

public struct TypeDescriptionKey: ResourcesKey, OptionalKey {
 public typealias Value = String
}

public struct TagNamesKey: ResourcesKey, OptionalKey {
 public typealias Value = [String]
}

// MARK: Resources
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

public extension Resources {
 var isDirectory: Bool { self[DirectoryKey.self] }
 var isHidden: Bool {
  get { self[HiddenKey.self] }
  set { self[HiddenKey.self] = newValue }
 }

 var isExecutable: Bool {
  get { self[ExecutableKey.self] }
  set { self[ExecutableKey.self] = newValue }
 }

 var urlFileResourceType: URLFileResourceType? {
  self[URLFileResourceTypeKey.self]
 }

 var contentType: UTType? {
  self[TypeIdentifierKey.self]
 }

 var contentDescription: String? {
  self[TypeDescriptionKey.self]
 }

 var tagNames: [String]? {
  get { self[TagNamesKey.self] }
  set { self[TagNamesKey.self] = newValue }
 }
}

// MARK: Extensions
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
