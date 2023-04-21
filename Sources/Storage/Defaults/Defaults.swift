@_exported import Composite
/// A key convertible ``UserDefaults`` that can be extended for the current
/// application
/// All the keys used in this namespace must be converted to and from
///  a nominal type accepted by ``UserDefaults``
public protocol Defaults: KeyValues {
 static var storage: UserDefaults { get }
 static func reset()
 var values: [String: Any] { get nonmutating set }
 subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
  get nonmutating set
 }
 subscript<A: ResolvedKey>(
  _ type: A.Type, default: A.ResolvedValue
 ) -> A.ResolvedValue {
  get nonmutating set
 }
}

public extension Defaults {
 unowned var storage: UserDefaults { Self.storage }
 func reset() { Self.reset() }
}

 public struct DefaultValues: Defaults {
  public init() {}
  public unowned static var storage: UserDefaults = .standard
  public static func reset() {
   for key in defaultValue.values.keys { storage.removeObject(forKey: key) }
  }

  @inlinable public var values: [String: Any] {
   get { Self.storage.dictionaryRepresentation() }
   nonmutating set {
    for (key, value) in newValue { Self.storage.set(value, forKey: key) }
   }
  }

  public subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
   get {
    A.resolveValue(Self.storage.value(forKey: type.description) as? A.Value)
   }
   nonmutating set {
    Self.storage.set(A.storeValue(newValue), forKey: type.description)
   }
  }

  public subscript<A: ResolvedKey>(
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

#if !canImport(SwiftUI)
 public typealias Default<Value> = DefaultProperty<DefaultValues, Value>
#endif
