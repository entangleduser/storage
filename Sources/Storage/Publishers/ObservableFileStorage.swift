// #if canImport(SwiftUI)
// import Combine
// import protocol SwiftUI.DynamicProperty
// import struct SwiftUI.Binding
//
////public protocol ObservableCache: ObservableObject, UserFileStorage
////where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
//// static var shared: Self { get }
////}
////
////public protocol StructuredObservableCache: ObservableCache, UserFileStorage
////where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
//// static var shared: Self { get }
////}
////
////public extension ObservableCache {
//// typealias File<Value, Key> = ObservableFileStorageProperty<Value, Key, Self>
////  where Value: Sendable & AutoCodable, Key: Transactional, Key.Source: Infallible
////
//// typealias OptionalFile<Value, Key> =
////  ObservableFileStorageProperty<Value, Key, Self>.Optional
////   where Value: Sendable & AutoCodable, Key: Transactional, Key.Source: Infallible
//// }
////
////public extension StructuredObservableCache {
//// typealias Structure<Value, Key> = ObservableFileStructure<Value, Key, Self>
//// where Value: Sendable & AutoCodable, Key: Transactional, Key.Source: Infallible
////
//// typealias OptionalStructure<Value, Key> =
//// OptionalObservableFileStructure<Value, Key, Self>
//// where Value: Sendable & AutoCodable, Key: Transactional, Key.Source: Infallible
////}
////
////public typealias DynamicTransactionalProperty = TransactionalProperty & DynamicProperty & Sendable
////
///// A cache property used to indicate a single value, structure, or location
// @propertyWrapper
// public struct ObservableFileStorageProperty
// <Value: Sendable & AutoCodable, Key, Container>: Sendable, TransactionalProperty
// where Key: Transactional, Key.Source: Infallible, Container: ObservableCache {
// var wrapper: Optional
// public var key: Key? { self.wrapper.key }
//
// public var wrappedValue: Value {
//  get { wrapper.wrappedValue! }
//  nonmutating set { wrapper.wrappedValue = newValue }
// }
//
// public var projectedValue: Binding<Value> {
//  Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
// }
//
// public func remove() throws { try wrapper.remove() }
//
// public init(wrappedValue: Value, _ key: Key) {
//  self.wrapper = Optional(wrappedValue: wrappedValue, key)
// }
// }
//
// extension ObservableFileStorageProperty {
// @propertyWrapper
// public struct Optional: DynamicTransactionalProperty {
//  // The prefix for storing files in a separate folder
//  public var key: Key?
//  public var container: Container? { .shared }
//
//  public var wrappedValue: Value? {
//   get {
//    do {
//     guard let container, let key else { return nil }
//     guard let data = try container.getData(for: key) else { return nil }
//     return try Value(data)
//    } catch {
//     debugPrint(error)
//     return nil
//    }
//   }
//   nonmutating set { self.set(newValue) }
//  }
//
//  @inline(__always) func set(_ newValue: Value?) {
//   guard let container, let key else { return }
//   container.objectWillChange.send()
//   do { try container.setData(newValue.data, for: key) }
//   catch { fatalError(error.localizedDescription) }
//  }
//
//  public var projectedValue: Binding<Value?> {
//   Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
//  }
//
//  /// - Note: Throws to validate the removal
//  public func remove() throws {
//   guard let key else { return }
//   try self.container?.removeData(for: key)
//  }
//
//  public init(wrappedValue: Value? = nil, _ key: Key? = nil) {
//   self.key = key
//   if let wrappedValue { self.set(wrappedValue) }
//  }
// }
// }
//
// @propertyWrapper
// public struct OptionalObservableFileStructure
// <Value: Sendable & AutoCodable, Key, Container>: DynamicTransactionalProperty
// where Key: Transactional, Key.Source: Infallible, Container: StructuredObservableCache {
//  // The prefix for storing files in a separate folder
// public var key: Key?
// public var container: Container? { .shared }
//
// public var wrappedValue: Value? {
//  get {
//   do {
//    guard let container, let key else { return nil }
//    guard let data = try container.getTargetData(for: key) else { return nil }
//    return try Value(data)
//   } catch {
//    debugPrint(error)
//    return nil
//   }
//  }
//  nonmutating set { set(newValue) }
// }
//
// @inline(__always) func set(_ newValue: Value?) {
//  guard let container, let key else { return }
//  container.objectWillChange.send()
//  do { try container.setTargetData(newValue.data, for: key) }
//  catch { fatalError(error.message) }
// }
//
// public var projectedValue: Binding<Value?> {
//  Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
// }
//
// /// - Note: Throws to validate the removal
// public func remove() throws {
//  guard let key else { return }
//  try self.container?.removeTargetData(for: key)
// }
//
// public init(wrappedValue: Value? = nil, _ key: Key? = nil) {
//  self.key = key
//  if let wrappedValue { self.set(wrappedValue) }
// }
// }
//
///// A cache property used to indicate a structure of potentially branching properties
// @propertyWrapper
// public struct ObservableFileStructure
// <Value: Sendable & AutoCodable, Key, Container>: TransactionalProperty
// where Key: Transactional, Key.Source: Infallible, Container: StructuredObservableCache {
// typealias Wrapper = OptionalObservableFileStructure<Value, Key, Container>
// // MARK: Non Optional
// let wrapper: Wrapper
// public var key: Key? { self.wrapper.key }
//
// public var wrappedValue: Value {
//  get { self.wrapper.wrappedValue! }
//  nonmutating set { wrapper.wrappedValue = newValue }
// }
//
// public var projectedValue: Binding<Value> {
//  Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
// }
//
// public func remove() throws { try self.wrapper.remove() }
//
// public init(wrappedValue: Value, _ key: Key) {
//  self.wrapper = Wrapper(wrappedValue: wrappedValue, key)
// }
// }
//
// public extension OptionalObservableFileStructure {
// //func update() { self.container?.objectWillChange.send() }
// }
//
// public extension ObservableFileStorageProperty.Optional {
// //func update() { self.container?.objectWillChange.send() }
// }
// #endif
