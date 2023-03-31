protocol ReflectedProperty: DynamicProperty, ReflectedContent {}
@testable @_exported import Core

/// The optional properties of content
@propertyWrapper
struct AttributeProperty<Value, Content: DynamicContent>: ReflectedProperty {
 unowned var _reflection: Reflection?
 let keyPath: WritableKeyPath<Attributes, Value>
 var defaultValue: Value?

 var wrappedValue: Value {
  get {
   guard let _reflection else { return Attributes.defaultValue[keyPath: keyPath] }
   return _reflection.attributes[keyPath: keyPath]
  }
  nonmutating set {
   guard let _reflection else { return }
   _reflection.attributes[keyPath: keyPath] = newValue
  }
 }

 var projectedValue: Value? {
  get { self.defaultValue }
  mutating set { defaultValue = newValue }
 }

 mutating func update() {
  if let defaultValue {
   _reflection?.attributes[keyPath: keyPath] = defaultValue
   self.defaultValue = nil
  }
 }

 init(wrappedValue: Value? = nil, _ keyPath: WritableKeyPath<Attributes, Value>) {
  if let wrappedValue { self.defaultValue = wrappedValue }
  self.keyPath = keyPath
 }
}

extension AttributeProperty: CustomStringConvertible
where Value: CustomStringConvertible {
 var description: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.description
 }
}

extension AttributeProperty: CustomDebugStringConvertible
where Value: CustomDebugStringConvertible {
 var debugDescription: String {
  guard _reflection != nil else { return "nil" }
  return wrappedValue.debugDescription
 }
}
