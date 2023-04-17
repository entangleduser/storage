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
