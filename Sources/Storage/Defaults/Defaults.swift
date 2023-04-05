@_exported @testable import Composite
protocol DefaultsKey: ResolvedKey {}
/// A key convertible ``UserDefaults`` that can be extended for the current
/// application
/// All the keys used in this namespace must be converted to and from
///  a nominal type accepted by ``UserDefaults``
protocol DefaultValues: KeyValues {
 static var storage: UserDefaults { get }
 static func reset()
 var values: [String: Any] { get nonmutating set }
 subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
  get nonmutating set
 }
}

extension DefaultValues { func reset() { Self.reset() } }

struct Defaults: DefaultValues {
 static var storage: UserDefaults = .standard
 static func reset() {
  for key in defaultValue.values.keys { storage.removeObject(forKey: key) }
 }

 @inlinable var values: [String: Any] {
  get { Self.storage.dictionaryRepresentation() }
  nonmutating set {
   for (key, value) in newValue { Self.storage.set(value, forKey: key) }
  }
 }

 subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
  get {
   A.resolveValue(Self.storage.value(forKey: type.description) as? A.Value)
  }
  nonmutating set {
   Self.storage.set(A.storeValue(newValue), forKey: type.description)
  }
 }

 subscript<A: ResolvedKey>(
  _ type: A.Type, default: A.ResolvedValue
 ) -> A.ResolvedValue {
  get {
   A.resolveValue(
    Self.storage.value(forKey: type.description) as? A.Value
   )
  }
  nonmutating set {
   Self.storage.set(
    A.storeValue(newValue) ?? `default`, forKey: type.description
   )
  }
 }
}

/// A key useful for storing auto codable values. Usually, within a defaults
/// protocol because it can provide uniform access to values
protocol AutoCodableKey: DefaultsKey
where ResolvedValue: AutoCodable, Value == Data {}

extension AutoCodableKey {
 @_disfavoredOverload
 static func resolveValue(_ data: Data?) -> ResolvedValue {
  do {
   guard let data else {
    throw Error.decoding(ResolvedValue.self, reason: "missing data!")
   }
   return try ResolvedValue.decoder.decode(ResolvedValue.self, from: data)
  } catch {
   fatalError(error.localizedDescription)
  }
 }

 static func storeValue(_ value: ResolvedValue?) -> Data? {
  guard let value else { return nil }
  do { return try ResolvedValue.encoder.encode(value) }
  catch {
   fatalError(error.localizedDescription)
  }
 }
}

extension AutoCodableKey where ResolvedValue: Infallible {
 static func resolveValue(_ data: Data?) -> ResolvedValue {
  do {
   guard let data else {
    throw Error.decoding(ResolvedValue.self, reason: "missing data!")
   }
   return try ResolvedValue.decoder.decode(ResolvedValue.self, from: data)
  } catch {
   return .defaultValue
  }
 }
}

/// MARK: Properties
@dynamicMemberLookup
@propertyWrapper
struct DefaultProperty
<Values: DefaultValues, Value>: DynamicProperty {
 let keyPath: ReferenceWritableKeyPath<Values, Value>
 @inlinable
 var wrappedValue: Value {
  get { self[dynamicMember: keyPath] }
  nonmutating set { self[dynamicMember: keyPath] = newValue }
 }

 @inlinable
 subscript<A>(dynamicMember path: ReferenceWritableKeyPath<Values, A>) -> A {
  get { Values.defaultValue[keyPath: path] }
  nonmutating set { Values.defaultValue[keyPath: path] = newValue }
 }

 func update() {}
}

extension DefaultProperty {
 init(_ keyPath: ReferenceWritableKeyPath<Values, Value>) {
  self.keyPath = keyPath
 }

 init(
  wrappedValue: Value,
  _ keyPath: ReferenceWritableKeyPath<Values, Value>
 ) {
  self.keyPath = keyPath
  if nil ~= self.wrappedValue {
   self.wrappedValue = wrappedValue
  }
 }
}

#if canImport(SwiftUI)
 import SwiftUI
 /// A publisher for saving default values within an app
 protocol PublishedDefaults: DefaultValues {
  associatedtype Publisher: StaticPublisher
  static var publisher: Publisher { get }
 }

 extension PublishedDefaults {
  static var publisher: Publisher { .standard }
  static func reset() {
   publisher.objectWillChange.send()
   for key in defaultValue.values.keys { storage.removeObject(forKey: key) }
  }

  subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
   get {
    A.resolveValue(Self.storage.value(forKey: type.description) as? A.Value)
   }
   nonmutating set {
    Self.publisher.objectWillChange.send()
    Self.storage.set(A.storeValue(newValue), forKey: type.description)
   }
  }

  subscript<A: ResolvedKey>(
   _ type: A.Type, default: A.ResolvedValue
  ) -> A.ResolvedValue {
   get {
    A.resolveValue(
     Self.storage.value(forKey: type.description) as? A.Value
    )
   }
   nonmutating set {
    Self.publisher.objectWillChange.send()
    Self.storage.set(
     A.storeValue(newValue) ?? `default`, forKey: type.description
    )
   }
  }
 }

 struct AppDefaults<Publisher: StaticPublisher>: PublishedDefaults {
  static var storage: UserDefaults { .standard }
  static var publisher: Publisher { .standard }

  @inlinable var values: [String: Any] {
   get { Self.storage.dictionaryRepresentation() }
   nonmutating set {
    Self.publisher.objectWillChange.send()
    for (key, value) in newValue {
     Self.storage.set(value, forKey: key)
    }
   }
  }
 }

 protocol DefaultsPublisher: StaticPublisher {
  typealias Defaults = AppDefaults<Self>
  typealias Default<Value> = DefaultProperty<Defaults, Value>
 }

 extension DefaultsPublisher {
  var defaults: Defaults { .defaultValue }
 }

 extension View {
  typealias Default<Value> =
   DefaultProperty<AppDefaults<DefaultPublisher>, Value>
  typealias ObservedDefault<A, Value> =
   DefaultProperty<AppDefaults<A>, Value>
    where A: ContentPublisher
 }

 extension DefaultProperty {
  var projectedValue: Binding<Value> {
   Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }
 }
#else
 typealias Default<Value> = DefaultProperty<Defaults, Value>
#endif
