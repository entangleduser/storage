/// The static properties of content
@propertyWrapper
public struct ResourceProperty
<Value, Content: Storage.Content>: ReflectedProperty {
 public unowned var _reflection: Reflection?
 public let keyPath: WritableKeyPath<Resources, Value>
 var defaultValue: Value?

 public var wrappedValue: Value {
  get {
   guard let _reflection else { fatalError() }
   return _reflection.resources[keyPath: keyPath]
  }
  nonmutating set {
   guard let _reflection else { return }
   _reflection.resources[keyPath: keyPath] = newValue
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
   defer { self.defaultValue = nil }
   _reflection.resources[keyPath: keyPath] = defaultValue
   _reflection.updateResources()
  }
 }

 public init(
  wrappedValue: Value? = nil, _ keyPath: WritableKeyPath<Resources, Value>
 ) {
  if let wrappedValue { self.defaultValue = wrappedValue }
  self.keyPath = keyPath
 }
}

extension ResourceProperty: CustomStringConvertible
where Value: CustomStringConvertible {
 public var description: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.description
 }
}

extension ResourceProperty: CustomDebugStringConvertible
where Value: CustomDebugStringConvertible {
 public var debugDescription: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.debugDescription
 }
}

public extension DynamicContent {
 typealias Resource<Value> = ResourceProperty<Value, Self>
}
