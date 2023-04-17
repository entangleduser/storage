@dynamicMemberLookup
@propertyWrapper
public struct DefaultProperty<Values: Defaults, Value> {
 public let keyPath: ReferenceWritableKeyPath<Values, Value>
 @inlinable public var wrappedValue: Value {
  get { self[dynamicMember: keyPath] }
  nonmutating set { self[dynamicMember: keyPath] = newValue }
 }

 @inlinable public var projectedValue: Binding<Value> {
  Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
 }

 @inlinable public
 subscript<A>(dynamicMember path: ReferenceWritableKeyPath<Values, A>) -> A {
  get { Values.defaultValue[keyPath: path] }
  nonmutating set { Values.defaultValue[keyPath: path] = newValue }
 }
}

public extension DefaultProperty {
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
