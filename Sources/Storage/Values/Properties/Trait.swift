/// The properties that define the behavior of dynamic content
@propertyWrapper
public struct TraitProperty
<Value, Content: Storage.Content>: ReflectedProperty {
 public unowned var _reflection: Reflection?
 public let keyPath: WritableKeyPath<Traits, Value>
 var defaultValue: Value?

 public var wrappedValue: Value {
  get {
   guard let _reflection else { fatalError() }
   return _reflection.traits[keyPath: keyPath]
  }
  nonmutating set {
   guard let _reflection else { return }
   _reflection.traits[keyPath: keyPath] = newValue
  }
 }

 /// The default value for the attribute
 public var projectedValue: Value? {
  get { defaultValue }
  mutating set { defaultValue = newValue }
 }

 public mutating func update() {
  guard let _reflection else { fatalError() }
  if let defaultValue {
   _reflection.resolveTraits()
   _reflection.traits[keyPath: keyPath] = defaultValue
  }
 }

 public init(
  wrappedValue: Value? = nil, _ keyPath: WritableKeyPath<Traits, Value>
 ) {
  if let wrappedValue { self.defaultValue = wrappedValue }
  self.keyPath = keyPath
 }
}

extension TraitProperty: CustomStringConvertible
where Value: CustomStringConvertible {
 public var description: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.description
 }
}

extension TraitProperty: CustomDebugStringConvertible
where Value: CustomDebugStringConvertible {
 public var debugDescription: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.debugDescription
 }
}

public extension DynamicContent {
 typealias Trait<Value> = TraitProperty<Value, Self>
}
