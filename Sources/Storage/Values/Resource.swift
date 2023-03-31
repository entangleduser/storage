@_exported @testable import Composite
protocol ResourcesKey: ResolvedKey {}

struct DirectoryKey: ResourcesKey, IntBoolKey {}

struct HiddenKey: ResourcesKey, IntBoolKey {}

struct ExecutableKey: ResourcesKey, IntBoolKey {}

struct URLFileResourceTypeKey: ResourcesKey, OptionalKey {
 typealias Value = URLFileResourceType
}

@_exported import UniformTypeIdentifiers
struct TypeIdentifierKey: ResourcesKey, OptionalKey {
 typealias Value = UTType
}

struct TypeDescriptionKey: ResourcesKey, OptionalKey {
 typealias Value = String
}

struct TagNamesKey: ResourcesKey, OptionalKey {
 typealias Value = [String]
}

extension Resources {
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
