#if canImport(SwiftUI)
 import SwiftUI
 /// A publisher for saving values associated with an app
 public protocol PublishedDefaults: Defaults {
  associatedtype Publisher: StaticPublisher
  associatedtype Values: Defaults
  static var defaults: Values { get }
  static var publisher: Publisher { get }
 }

 public extension PublishedDefaults {
  var defaults: Values { Self.defaults }
  static var storage: UserDefaults { defaults.storage }
  unowned static var publisher: Publisher { .standard }
  unowned var publisher: Publisher { Self.publisher }

  static func reset() {
   defer { publisher.objectWillChange.send() }
   defaults.reset()
  }

  @inlinable var values: [String: Any] {
   get { storage.dictionaryRepresentation() }
   nonmutating set {
    defer { publisher.objectWillChange.send() }
    defaults.values = newValue
   }
  }

  subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
   get { defaults[type] }
   nonmutating set {
    defer { publisher.objectWillChange.send() }
    defaults[type] = newValue
   }
  }

  subscript<A: ResolvedKey>(
   _ type: A.Type, default: A.ResolvedValue
  ) -> A.ResolvedValue {
   get { defaults[type, `default`] }
   nonmutating set {
    defer { publisher.objectWillChange.send() }
    defaults[type, `default`] = newValue
   }
  }
 }

 public struct AppDefaults<Publisher: StaticPublisher>: PublishedDefaults {
  public init() {}
  public static var defaults: DefaultValues { .defaultValue }
  public static var publisher: Publisher { .standard }
 }

 public extension DefaultsPublisher {
  var defaults: Defaults { .defaultValue }
 }

 public protocol DefaultsPublisher: StaticPublisher {
  typealias Defaults = AppDefaults<Self>
  typealias Default<Value> = AppDefaultProperty<Defaults, Value>
 }

 public extension View {
  typealias Default<Value> =
   AppDefaultProperty<AppDefaults<DefaultPublisher>, Value>
  typealias ObservedDefault<A, Value> =
   AppDefaultProperty<AppDefaults<A>, Value> where A: StaticPublisher
 }
#endif
