@_exported import Composite
public protocol TraitKey: ResolvedKey {}

public struct ObservableKey: TraitKey, DefaultKey {
 public static let defaultValue = true
}

public struct ContentTypeKey: TraitKey, OptionalKey {
 public typealias Value = ContentType
}

public struct RecursiveKey: TraitKey, DefaultKey {
 public typealias Value = Bool
}

public struct RemovalMethodKey: TraitKey, DefaultKey {
 public typealias Value = RemovalMethod
}

public struct CreateMethodKey: TraitKey, DefaultKey {
 public typealias Value = CreateMethod
}

public struct UTTypeKey: TraitKey, OptionalKey {
 public typealias Value = UTType
}

public struct ContentKey: TraitKey, OptionalKey {
 public typealias Value = AnyHashable
}

// MARK: Traits
/// The traits of a `Content` structure that are used to change
/// the way values are collected
public struct Traits: KeyValues {
 public init() {}
 public var values: [String: Any] = .empty
 public static var defaultValues: OrderedDictionary<String, Any> {
  [
   ObservableKey.description: ObservableKey.defaultValue,
   ContentTypeKey.description: ContentTypeKey.resolvedValue as Any,
   RecursiveKey.description: RecursiveKey.defaultValue,
   RemovalMethodKey.description: RemovalMethodKey.defaultValue,
   CreateMethodKey.description: CreateMethodKey.defaultValue,
   UTTypeKey.description: UTTypeKey.resolvedValue as Any,
   ContentKey.description: ContentKey.resolvedValue as Any
  ]
 }
}

public extension Traits {
 var key: AnyHashable? {
  get { self[ContentKey.self] }
  set { self[ContentKey.self] = newValue }
 }

 var isObservable: Bool {
  get { self[ObservableKey.self] }
  set { self[ObservableKey.self] = newValue }
 }

 var utType: UTType? {
  get { self[UTTypeKey.self] }
  set { self[UTTypeKey.self] = newValue }
 }

 var isRecursive: Bool {
  get { self[RecursiveKey.self] }
  set { self[RecursiveKey.self] = newValue }
 }

 var contentType: ContentType? {
  get { self[ContentTypeKey.self] }
  set { self[ContentTypeKey.self] = newValue }
 }

 var removalMethod: RemovalMethod {
  get { self[RemovalMethodKey.self] }
  set { self[RemovalMethodKey.self] = newValue }
 }

 var createMethod: CreateMethod {
  get { self[CreateMethodKey.self] }
  set { self[CreateMethodKey.self] = newValue }
 }
}

// MARK: Extensions
public extension UTType {
 static let markdown = Self(filenameExtension: "md", conformingTo: .text)!
}
