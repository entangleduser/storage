#if canImport(SwiftUI)
 @propertyWrapper
 public struct AppDefaultProperty<Defaults: Storage.PublishedDefaults, Value>:
 DynamicProperty {
  public typealias Values = Defaults.Values
  public let keyPath: ReferenceWritableKeyPath<Values, Value>
  @inlinable public var wrappedValue: Value {
   get { Defaults.defaults[keyPath: keyPath] }
   nonmutating set {
    Defaults.publisher.objectWillChange.send()
    Defaults.defaults[keyPath: keyPath] = newValue
   }
  }

  @inlinable public var projectedValue: Binding<Value> {
   Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }

  public func update() { Defaults.publisher.objectWillChange.send() }
 }

 public extension AppDefaultProperty {
  init(_ keyPath: ReferenceWritableKeyPath<Values, Value>) {
   self.keyPath = keyPath
  }

  // MARK: Default value initializers
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Values, Value>
  ) {
   self.keyPath = keyPath
   if nil ~= Defaults.defaults[keyPath: keyPath] {
    Defaults.defaults[keyPath: keyPath] = wrappedValue
   }
  }
 }

 // MARK: Reset initializers
 public extension AppDefaultProperty {
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Value
  ) {
   self.keyPath = keyPath
   if nil ~= Defaults.defaults[keyPath: keyPath] {
    Defaults.defaults[keyPath: keyPath] = wrappedValue
   } else {
    Defaults.defaults[keyPath: keyPath] = reset
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Value
  ) {
   self.keyPath = keyPath
   Defaults.defaults[keyPath: keyPath] = reset
  }
 }

 public extension AppDefaultProperty where Value: ExpressibleByNilLiteral {
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if nil ~= Defaults.defaults[keyPath: keyPath] {
    Defaults.defaults[keyPath: keyPath] = wrappedValue
   } else if reset {
    Defaults.defaults[keyPath: keyPath] = nil
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if reset { Defaults.defaults[keyPath: keyPath] = nil }
  }
 }

 public extension AppDefaultProperty where Value: Infallible {
  init(
   wrappedValue: Value,
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if nil ~= Defaults.defaults[keyPath: keyPath] {
    Defaults.defaults[keyPath: keyPath] = wrappedValue
   } else if reset {
    Defaults.defaults[keyPath: keyPath] = .defaultValue
   }
  }

  init(
   _ keyPath: ReferenceWritableKeyPath<Values, Value>,
   reset: Bool
  ) {
   self.keyPath = keyPath
   if reset { Defaults.defaults[keyPath: keyPath] = .defaultValue }
  }
 }
#endif
