/// A dynamic property updates the contents of a filesystem
@testable @_exported import Core
@propertyWrapper final class Alias<Value>: DynamicProperty
where Value: ExpressibleByNilLiteral {
 unowned var _reflection: Reflection?
 var wrappedValue: Value {
  get {
   guard let _reflection else { return nil }
   return _reflection[Value.self] ?? nil
  }
  set {
   guard let _reflection else { fatalError("\(Self.self) not set to content") }
   _reflection[Value.self] = newValue
  }
 }

 var projectedValue: Alias<Value> { self }
 var binding: Binding<Value> {
  Binding(get: { self.wrappedValue }, set:  { self.wrappedValue = $0 })
 }
 
 subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>
 ) -> Subject? {
  get { wrappedValue[keyPath: keyPath] }
  set {
   guard let newValue else { return }
   wrappedValue[keyPath: keyPath] = newValue
  }
 }

 func update() {
  guard let _reflection else { return }
  if _reflection.update() {
   #if DEBUG
    print("Updated \(Self.self)")
   #endif
  } else {
   #if DEBUG
    print("Deleted or missing \(Self.self)")
   #endif
  }
 }
}

extension Alias {
 func trash(_ recovery: ((_ recoveryURL: URL?) -> Void)? = nil) {
  guard let _reflection else { return }
  do {
   try _reflection.trash()
   recovery?(_reflection.recoveryURL)
  } catch {
   _reflection.onError?(.url(error))
  }
 }

 func delete() {
  guard let _reflection else { return }
  do { try _reflection.delete() }
  catch { _reflection.onError?(.url(error)) }
 }

 func remove() {
  guard let _reflection else { return }
  do { try _reflection.remove() }
  catch { _reflection.onError?(.url(error)) }
 }
}

extension Alias {
 /// Retrieves the value associated with `NominalContent`
 /// Transactional tokens effectively change the name of the structure
 /// when needed
 func get(_ id: some LosslessStringConvertible) -> Value {
  guard let _reflection else { fatalError() }
  return _reflection.get(id: id, as: Value.self)
 }

 /// Sets the associated value to `NominalContent`
 func set(
  _ newValue: Value,
  with id: some LosslessStringConvertible
 ) {
  guard let _reflection else { fatalError() }
  _reflection.set(newValue, id: id)
 }

 /// Subscript a property via direct transaction through the source value
 subscript(
  _ id: some LosslessStringConvertible
 ) -> Value {
  get { get(id) }
  set { set(newValue, with: id) }
 }
}

/*// MARK: Queries and filters for variadic content
extension Alias where Value: Sequence {
 /// Recieves a group of values based on a filter or criteria
 func get() -> Value {
  nil
 }

 func set() -> Value { nil }
}*/

extension Alias: Identifiable where Value: Identifiable {
 var id: Value.ID? { wrappedValue.id }
}

extension Alias: CustomStringConvertible where Value: CustomStringConvertible {
 var description: String { wrappedValue.description }
}

extension Alias: CustomDebugStringConvertible
where Value: CustomDebugStringConvertible {
 var debugDescription: String { wrappedValue.debugDescription }
}

/*
 extension Alias: Sequence where Value: MutableCollection {
  typealias Element = Alias<Value.Element>
  typealias Iterator = IndexingIterator<Alias<Value>>
  typealias SubSequence = Slice<Alias<Value>>
  }

  extension Alias: Collection where Value: MutableCollection {
  typealias Index = Value.Index
  typealias Indices = Value.Indices
  var startIndex: Alias<Value>.Index { self.wrappedValue.startIndex }
  var endIndex: Alias<Value>.Index { self.wrappedValue.endIndex }
  var indices: Value.Indices { self.wrappedValue.indices }

  func index(after i: Alias<Value>.Index) -> Alias<Value>.Index {
   self.wrappedValue.index(after: i)
  }

  func formIndex(after i: inout Alias<Value>.Index) {
   self.wrappedValue.formIndex(after: &i)
  }

  subscript(position: Alias<Value>.Index) -> Alias<Value>.Element {
   Alias<Value.Element> {
    wrappedValue[position]
   } set: {
    wrappedValue[position] = $0
   }
  }
  }

  extension Alias: BidirectionalCollection
  where Value: BidirectionalCollection, Value: MutableCollection {
  func index(before i: Alias<Value>.Index) -> Alias<Value>.Index {
   self.wrappedValue.index(before: i)
  }

  func formIndex(before i: inout Alias<Value>.Index) {
   self.wrappedValue.formIndex(before: &i)
  }
  }

  extension Alias: RandomAccessCollection
  where Value: MutableCollection, Value: RandomAccessCollection {}
 */
