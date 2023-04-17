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

public extension UTType {
 static let markdown = Self(filenameExtension: "md", conformingTo: .text)!
}
