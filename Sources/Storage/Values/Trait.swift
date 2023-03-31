@_exported @testable import Composite
protocol TraitKey: ResolvedKey {}

struct ObservableKey: TraitKey, DefaultKey {
 static let defaultValue = true
}

struct ContentTypeKey: TraitKey, OptionalKey {
 typealias Value = ContentType
}

struct RecursiveKey: TraitKey, DefaultKey {
 typealias Value = Bool
}

struct RemovalMethodKey: TraitKey, DefaultKey {
 typealias Value = RemovalMethod
}

struct CreateMethodKey: TraitKey, DefaultKey {
 typealias Value = CreateMethod
}

struct UTTypeKey: TraitKey, OptionalKey {
 typealias Value = UTType
}

extension Traits {
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

extension UTType {
 static let markdown = Self(filenameExtension: "md", conformingTo: .text)!
}
