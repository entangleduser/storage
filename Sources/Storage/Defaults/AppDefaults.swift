#if canImport(SwiftUI)
 import SwiftUI
 /// A publisher for saving values associated with an app
 public protocol PublishedDefaults: Defaults {
  associatedtype Publisher: StaticPublisher
  static var publisher: Publisher { get }
 }

 public extension PublishedDefaults {
  unowned static var publisher: Publisher { .standard }
  unowned var publisher: Publisher { Self.publisher }

  static func reset() {
   publisher.objectWillChange.send()
   for key in defaultValue.values.keys { storage.removeObject(forKey: key) }
  }

  subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
   get {
    A.resolveValue(storage.value(forKey: type.description) as? A.Value)
   }
   nonmutating set {
    defer { publisher.objectWillChange.send() }
    storage.set(A.storeValue(newValue), forKey: type.description)
   }
  }

  subscript<A: ResolvedKey>(
   _ type: A.Type, default: A.ResolvedValue
  ) -> A.ResolvedValue {
   get {
    A.resolveValue(
     storage.value(forKey: type.description) as? A.Value
    )
   }
   nonmutating set {
    // defer { publisher.objectWillChange.send() }
    storage.set(
     A.storeValue(newValue) ?? `default`, forKey: type.description
    )
   }
  }
 }

 public struct AppDefaults<Publisher: StaticPublisher>: PublishedDefaults {
  public init() {}
  public static var storage: UserDefaults { .standard }
  public static var publisher: Publisher { .standard }
  @inlinable public var values: [String: Any] {
   get { storage.dictionaryRepresentation() }
   nonmutating set {
    defer { publisher.objectWillChange.send() }
    for (key, value) in newValue {
     storage.set(value, forKey: key)
    }
   }
  }
 }

 public protocol DefaultsPublisher: StaticPublisher {
  typealias Defaults = AppDefaults<Self>
  typealias Default<Value> = DefaultProperty<Defaults, Value>
 }

 public extension DefaultsPublisher {
  var defaults: Defaults { .defaultValue }
 }

 public extension View {
  typealias Default<Value> =
   DefaultProperty<AppDefaults<DefaultPublisher>, Value>
  typealias ObservedDefault<A, Value> =
   DefaultProperty<AppDefaults<A>, Value> where A: StaticPublisher
 }
#endif
