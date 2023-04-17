@testable @_exported import Core
@propertyWrapper struct PublicContentProperty
<A: PublicContent, Publisher: ContentPublisher & ContentCache>: DynamicProperty {
 var publisher: Publisher { .standard }
 var value: A? {
  get { publisher[content: A.self] }
  set { publisher[content: A.self] = newValue }
 }

 var wrappedValue: A {
  get { value ?? A.defaultValue.publish(publisher) }
  set { value = newValue }
 }

 func update() { publisher.objectWillChange.send() }
 init() {}
}

@propertyWrapper
public struct ObservableContent<Publisher: ContentPublisher>: DynamicProperty {
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

 public init(wrappedValue: Publisher = .standard) {
  self.projectedValue = Wrapper(publisher: wrappedValue)
 }

 public let projectedValue: Wrapper
 public func update() { wrappedValue.objectWillChange.send() }
}

extension ContentPublisher where Self: ContentCache {
 typealias Public<A> = PublicContentProperty<A, Self> where A: PublicContent
}

/// Content that can be set on a ``ContentPublisher``
public protocol PublicContent: DynamicContent, Infallible {
 init()
}

public extension PublicContent {
 static var defaultValue: Self { Self() }
 /// `PublicContent` must have an actor to process the entire structure
 /// and determine the domain for managing it's contents
 func publish(_ publisher: AnyContentPublisher) -> Self {
  Storage.Contents.caching(for: publisher, contents: { self })
   as? Self ?? .defaultValue
 }
}

public extension PublicContent {
 @_disfavoredOverload
 unowned var _reflection: Reflection? {
  get {
   if let property = info.properties
    .last(where: {
     $0 is any ReflectedProperty && !($0 is any IdentifiableProperty)
//     ["AttributeProperty"].contains(String.withName(for: $0.type))
    }) {
    return (property.get(from: self) as! any ReflectedProperty)._reflection
   } else {
    return nil
   }
  }
  nonmutating set {
   var reflection = self._reflection
   reflection = newValue
   _ = reflection
  }
 }
}

extension Content {
 var isPublic: Bool { self is any PublicContent }
}
