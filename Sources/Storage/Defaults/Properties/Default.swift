#if !canImport(SwiftUI)
 @dynamicMemberLookup
 @propertyWrapper
 public struct DefaultProperty<Defaults: Storage.Defaults, Value> {
  public let keyPath: ReferenceWritableKeyPath<Defaults, Value>
  @inlinable public var wrappedValue: Value {
   get { self[dynamicMember: keyPath] }
   nonmutating set { self[dynamicMember: keyPath] = newValue }
  }

  @inlinable public var projectedValue: Binding<Value> {
   Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }

  @inlinable public
  subscript<A>(dynamicMember path: ReferenceWritableKeyPath<Defaults, A>) -> A {
   get { Defaults.defaultValue[keyPath: path] }
   nonmutating set { Defaults.defaultValue[keyPath: path] = newValue }
  }
 }

 public extension DefaultProperty {
  init(_ keyPath: ReferenceWritableKeyPath<Defaults, Value>) {
   self.keyPath = keyPath
  }

  // MARK: Default value initializers
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>
  ) {
   self.keyPath = keyPath
   if nil ~= self.wrappedValue {
    self.wrappedValue = wrappedValue
   }
  }
 }

 public extension DefaultProperty {
  // MARK: Reset initializers
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Value
  ) {
   self.keyPath = keyPath
   if nil ~= self.wrappedValue {
    self.wrappedValue = wrappedValue
   } else {
    self.wrappedValue = reset
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Value
  ) {
   self.keyPath = keyPath
   self.wrappedValue = reset
  }
 }

 public extension DefaultProperty where Value: ExpressibleByNilLiteral {
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if nil ~= self.wrappedValue {
    self.wrappedValue = wrappedValue
   } else if reset {
    self.wrappedValue = nil
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if reset { self.wrappedValue = nil }
  }
 }

 public extension DefaultProperty where Value: Infallible {
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if nil ~= self.wrappedValue {
    self.wrappedValue = wrappedValue
   } else if reset {
    self.wrappedValue = .defaultValue
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Defaults, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if reset { self.wrappedValue = .defaultValue }
  }
 }
#endif
