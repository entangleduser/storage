@testable @_exported import Core
@propertyWrapper struct PublicContentProperty
<A: PublicContent, Publisher: ContentPublisher>: DynamicProperty {
 var publisher: Publisher { .standard }
 var value: A? {
  get { publisher[content: A.self] }
  set { publisher[content: A.self] = newValue }
 }

 var wrappedValue: A {
  get { value ?? A.defaultValue.publish(publisher) }
  set { value = newValue }
 }

 func update() {}
 init() {}
}

@propertyWrapper
struct ObservableContent<Publisher: ContentPublisher> {
 @dynamicMemberLookup
 public struct Wrapper {
  let publisher: Publisher
  public subscript<Subject>(
   dynamicMember keyPath: ReferenceWritableKeyPath<Publisher, Subject>
  ) -> Binding<Subject> {
   Binding(
    get: { self.publisher[keyPath: keyPath] },
    set: { self.publisher[keyPath: keyPath] = $0 }
   )
  }
 }

 public var wrappedValue: Publisher { projectedValue.publisher }

 public init(wrappedValue: Publisher) {
  self.projectedValue = Wrapper(publisher: wrappedValue)
 }

 public let projectedValue: Wrapper
}

extension ContentPublisher {
 typealias Public<A> = PublicContentProperty<A, Self> where A: PublicContent
}

/// Content that can be set on a ``ContentPublisher``
protocol PublicContent: DynamicContent, Infallible {
 func publish(_ publisher: some ContentPublisher) -> Self
 init()
}

extension PublicContent {
 var _traits: Traits? { get { nil } set {} }
 var _attributes: Attributes? { get { nil } set {} }
 /// `PublicContent` must have an actor to process the entire structure
 /// and determine the domain for managing it's contents
 func publish(_ publisher: some ContentPublisher) -> Self {
  Storage.Contents.mirroring(contents: { self }, for: publisher)
 }

 static var defaultValue: Self { Self() }
}

extension PublicContent {
 @_disfavoredOverload
 unowned var _reflection: Reflection? {
  get {
   if let property = info.properties
    .last(where: { $0.get(from: self) is any ReflectedContent }) {
    return (property.get(from: self) as! any ReflectedContent)._reflection
   } else {
    return nil
   }
  }
  nonmutating set {
//   unowned var reflection = self._reflection
//   reflection = newValue
  }
 }
}

extension Content {
 var isPublic: Bool { self is any PublicContent }
}
