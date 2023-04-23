import Composite
// Content that can be encoded and decoded, as well as modified to provide
// access to the structure
public protocol EnclosedContent:
IdentifiableContent, EnumeratedContents, ReflectedProperty {
 var defaultValue: Value? { get set }
 @discardableResult func encode(_ value: Value) throws -> Data
 func decode(_ data: Data) throws -> Value
 func get() -> Value?
 func set(_ newValue: Value?)
 func create() throws
 mutating func update(_ reflection: Reflection)
}

public extension EnclosedContent {
 func decode(_ data: Data) throws -> Value { fatalError() }
 func encode(_ value: Value) throws -> Data { fatalError() }

 func encode(any value: Any) throws -> Data? {
  guard let _reflection else { fatalError() }
  guard let newValue = value as? Value? else {
   throw Error.decoding(Swift.type(of: value), reason: "bad format")
  }
  guard let newValue else {
   _reflection.remove()
   return nil
  }
  return try encode(newValue)
 }

 func decode<A>(any data: Data, as: A.Type) throws -> A? {
  try decode(data) as? A
 }

 func get() -> Value? { _reflection?[self] }
 func set(_ newValue: Value?) { _reflection?[self] = newValue }
 func set<A>(any newValue: A?) { _reflection?[A.self] = newValue }

 func create() throws {
  guard let _reflection, let publisher = _reflection.publisher else { return }
  do {
   if _traits.createMethod == .automatic,
      !_reflection.exists, let defaultValue {
    try publisher.createFile(
     atPath: _reflection.path ?? _reflection.url.path,
     contents: encode(defaultValue)
    )
   }
  } catch let error as Error {
   _reflection.onError?(error)
  } catch {
   _reflection.onError?(.set(error))
  }
 }

 mutating func update(_ reflection: Reflection) {
  // only used to encode and decode data after updating the reflection
  _reflection = reflection
  reflection.traits.merge(with: _traits)

  if _traits.utType != nil, let name = id.description.wrapped {
   reflection.name = name
  } else if let name = id.description.wrapped {
   reflection.name = name
  }

  reflection.resolveTraits()
  reflection.attributes.merge(with: _attributes)
  reflection.structure = self

  do { try create() }
  catch {
   reflection.onError?(Error.create(error))
  }

  reflection.setAttributes()
 }

 static func ?? (lhs: Self, rhs: Value) -> Self {
  if lhs.defaultValue != nil { return lhs }
  else {
   var copy = lhs
   copy.defaultValue = rhs
   return copy
  }
 }
}

public extension EnclosedContent {
 /// Update function for updating the property wrapper when updating the mirror
 func update() {
  guard let _reflection else { fatalError() }
  #if DEBUG
   log("Updated \(Self.self) for \(_reflection.keyType)", for: .structure)
  #endif
 }

 /// A function most likely to be used with different types of data
 /// so the updated copy will be cached rather than setting the main structure
 /// on the reflection as a property
 /// This could be an observable structure, with the use of inner reflections
 /// but there's really no need to observe cached values unless the operation
 /// happens outside of the cache
 func attach(to reflection: Reflection) {
  Task {
   var copy = self
   copy.update(reflection)
   reflection.structure = copy
  }
 }

 subscript<A: Identifiable>(value: A) -> Value?
  where A == Value, A.ID: LosslessStringConvertible {
  get {
   _reflection.unsafelyUnwrapped.get(id: value.id, on: self)
  }
  nonmutating set {
   guard let _reflection else { return }
   defer { _reflection.updateIndex() }
   _reflection.set(newValue, id: value.id, on: self)
  }
 }

// var dictionary: [AnyHashable: Value?] {
//  get {
//   guard let keyPath else { return .empty }
//   return Dictionary(
//    uniqueKeysWithValues:
//     values.map { ($0[keyPath: keyPath], $0) }
//   )
//  }
//  nonmutating set {
//   guard let _reflection else { return }
//   defer {
//    _reflection.structure = nil
//    _reflection.updateIndex()
//   }
//   attach(to: _reflection)
//   for (key, value) in newValue {
//     if let value {
//      _reflection.set(value, id: key)
//     } else {
//      _reflection.set(Value?.none, id: key)
//     }
//   }
//  }
// }

 var values: [Value] {
  get {
   guard let _reflection else { return .empty }
   // defer { _reflection.publisher.objectWillChange.send() }
   /// lookup preferrably cached values so the returned data is unambiguous
   return _reflection.getAll(on: self)
  }
  nonmutating set {
   guard let _reflection, let keyPath else { return }
   defer { _reflection.updateIndex() }
   // cache and compare old values
   // TODO: Resolve ambiguities when appending more than one value
   switch newValue.count {
   case .zero:
    let oldValues = _reflection.getAll(on: self)
    for oldValue in oldValues {
     let key = oldValue[keyPath: keyPath]
     _reflection.set(nil, id: key, on: self)
    }
   case 1:
    let value = newValue.first.unsafelyUnwrapped
    _reflection.set(value, id: value[keyPath: keyPath], on: self)
   case 2...:
    let newValues = newValue
    let oldValues = _reflection.getAll(on: self)
    if oldValues.count != newValues.count {
     for oldValue in oldValues {
      let key = oldValue[keyPath: keyPath]
      if !newValue.contains(where: { $0[keyPath: keyPath] == key }) {
       _reflection.set(nil, id: key, on: self)
      }
     }
    }
    for value in newValue {
     _reflection.set(value, id: value[keyPath: keyPath], on: self)
    }
   default:
    fatalError()
   }
  }
 }
}

// MARK: Structures
@propertyWrapper
public struct Structure<Value, Encoder, Decoder>: CodableContent where
 Value: Codable,
 Encoder: TopLevelEncoder, Decoder: TopLevelDecoder,
 Encoder.Output == Data, Decoder.Input == Data {
 public var _reflection: Reflection?
 public var _traits: Traits = .observable
 public var _attributes: Attributes = .defaultValue

 public var id: String = .empty
 public var keyPath: KeyPath<Value, AnyHashable>?
 public var defaultValue: Value?

 public var wrappedValue: [Value] {
  get { values }
  nonmutating set { values = newValue }
 }

 public var projectedValue: Self {
  get { self }
  set { self = newValue }
 }

 public var encoder: Encoder
 public var decoder: Decoder

 @_disfavoredOverload
 public init() {
  fatalError("A decoder/encoder is needed to initialize \(Self.self)")
 }
}

public extension Structure where Encoder == JSONEncoder, Decoder == JSONDecoder {
 init(
  _ name: AnyHashable? = nil, default value: Value? = nil
 ) {
  self.id = name.description
  self.defaultValue = value
  self.encoder = JSONEncoder()
  self.decoder = JSONDecoder()
 }

 init(default value: Value? = nil) {
  self.defaultValue = value
  self.encoder = JSONEncoder()
  self.decoder = JSONDecoder()
 }
}

public extension Structure
where Value: Infallible, Encoder == JSONEncoder, Decoder == JSONDecoder {
 /// The property can be set to nil to reflect changes
 init(
  _ name: AnyHashable? = nil,
  default value: Value = .defaultValue
 ) {
  self.id = name.description
  self.defaultValue = value
  self.encoder = JSONEncoder()
  self.decoder = JSONDecoder()
 }
}

public extension Structure where
 Encoder == JSONEncoder, Decoder == JSONDecoder,
 Value: Identifiable, Value.ID: LosslessStringConvertible {
 init(
  wrappedValue: [Value] = .empty,
  _ type: UTType? = .json, default value: Value? = nil
 ) {
  self.init(String?.none, default: value)
  _traits.utType = type
  self.keyPath = \.id.description.erasedToAny
 }
}

public extension Structure
 where Value: AutoCodable,
 Encoder == Value.AutoEncoder, Decoder == Value.AutoDecoder {
 /// The property can be set to nil to reflect changes
 init(
  _ name: AnyHashable? = nil,
  default value: Value? = nil
 ) {
  if let name { self.id = name.description }
  self.defaultValue = value
  self.encoder = Value.encoder
  self.decoder = Value.decoder
 }
}

public extension Structure where
 Value: Identifiable & AutoCodable, Value.ID: LosslessStringConvertible,
 Encoder == Value.AutoEncoder, Decoder == Value.AutoDecoder {
 init(
  wrappedValue: [Value] = .empty,
  _ type: UTType? = nil, default value: Value? = nil
 ) {
  self.init(String?.none, default: value)
  _traits.utType = type
  self.keyPath = \.id.description.erasedToAny
 }
}

public extension Content {
 typealias JSON<Value> =
  Structure<Value, JSONEncoder, JSONDecoder> where Value: Codable
 typealias Auto<Value> =
  Structure<Value, Value.AutoEncoder, Value.AutoDecoder>
   where Value: AutoCodable
}

#if canImport(XMLCoder)
 import XMLCoder
 public extension Structure where Encoder == XMLEncoder, Decoder == XMLDecoder {
  @_disfavoredOverload
  init(_ name: AnyHashable, default value: Value? = nil) {
   self.id = name.description
   self.defaultValue = value
   self.encoder = XMLEncoder()
   self.decoder = XMLDecoder()
  }

  @_disfavoredOverload
  init(default value: Value? = nil) {
   self.defaultValue = value
   self.encoder = XMLEncoder()
   self.decoder = XMLDecoder()
  }
 }

 public extension Structure where
  Encoder == XMLEncoder, Decoder == XMLDecoder,
  Value: Identifiable, Value.ID: LosslessStringConvertible {
  init(
   wrappedValue: [Value] = .empty,
   _ type: UTType = .xml, default value: Value? = nil
  ) {
   self.init(String?.none, default: value)
   self.keyPath = \.id.description.erasedToAny
   _traits.utType = type
  }
 }

 public extension Structure
 where Value: Infallible, Encoder == XMLEncoder, Decoder == XMLDecoder {
  /// The property can be set to nil to reflect changes
  init(
   _ name: AnyHashable, default value: Value = .defaultValue
  ) {
   self.id = name.description
   self.defaultValue = value
   self.encoder = XMLEncoder()
   self.decoder = XMLDecoder()
  }
 }

 public extension Content {
  typealias XML<Value> =
   Structure<Value, XMLEncoder, XMLDecoder> where Value: Codable
 }
#endif

#if canImport(CodableCSV)
 import CodableCSV
 public extension Content {
  typealias CVS<Value> =
   Structure<Value, CVSEncoder, CVSDecoder> where Value: Codable
 }
#endif

@propertyWrapper
public struct NominalStructure<Value: StaticCodable>: EnclosedContent {
 public init() {}
 public var _reflection: Reflection?
 public var _traits: Traits = .observable
 public var _attributes: Attributes = .defaultValue

 public var keyPath: KeyPath<Value, AnyHashable>?
 public var id: String = .empty
 public var defaultValue: Value?

 public var wrappedValue: [Value] {
  get { values }
  nonmutating set { values = newValue }
 }

 public var projectedValue: Self {
  get { self }
  set { self = newValue }
 }

 public func decode(_ data: Data) throws -> Value { try Value.decode(data) }
 public func encode(_ value: Value) throws -> Data { try Value.encode(value) }
}

public extension NominalStructure {
 /// The property can be set to nil to reflect changes
 init(_ name: AnyHashable, default value: Value? = nil) {
  self.id = name.description
  self.defaultValue = value
 }

 /// The property can be set to nil to reflect changes
 init(
  _ name: AnyHashable,
  _ type: UTType? = nil, default value: Value? = nil
 ) {
  self.id = name.description
  if let value { self.defaultValue = value }
  _traits.utType = type
 }

 init(wrappedValue: Value? = nil, _ type: UTType?) {
  self.defaultValue = wrappedValue
  _traits.utType = type
 }
}

public extension Content {
 typealias Nominal<Value> = NominalStructure<Value>
  where Value: StaticCodable
}

// MARK: Structured Content Modifiers
/// A modifier for `EnclosedContent`, or content that can be encoded and decoded
public protocol StructureModifier: AttributeModifier, DynamicContent
where Enclosure: EnclosedContent, Value == Enclosure.Value {
 var identifier: UUID { get }
 var enclosure: Enclosure { get set }
 var onError: ((Error) -> Void)? { get }
 mutating func update()
}

public extension StructureModifier {
 mutating func update() {
  guard let _reflection else { fatalError() }
  _reflection.traits.merge(with: _traits)
  _reflection.attributes.merge(with: _attributes)
  _reflection.onError = onError
  _reflection.structure = enclosure

  enclosure.update(_reflection)
 }
}

public struct CodableContentModifier<
 Value: Codable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder
>: StructureModifier
where Encoder.Output == Data, Decoder.Input == Data {
 public typealias Enclosure = Structure<Value, Encoder, Decoder>
 public var _reflection: Reflection?
 public var _traits: Traits = .observable
 public var _attributes: Attributes = .defaultValue
 public let identifier: UUID
 public var enclosure: Structure<Value, Encoder, Decoder>
 public let onError: ((Error) -> Void)?
}

public extension Structure {
 func alias(
  _ alias: Alias<Value?>, onError: ((Error) -> Void)? = nil
 ) -> CodableContentModifier<Value, Encoder, Decoder> {
  CodableContentModifier(
   identifier: alias.identifier, enclosure: self, onError: onError
  )
 }
}

public struct NominalContentModifier<Value: StaticCodable>: StructureModifier {
 public typealias Enclosure = NominalStructure<Value>
 public let identifier: UUID
 public var _reflection: Reflection?
 public var _traits: Traits = .observable
 public var _attributes: Attributes = .defaultValue
 public var enclosure: NominalStructure<Value>
 public let onError: ((Error) -> Void)?
}

public extension NominalStructure where Value: StaticCodable {
 func alias(
  _ alias: Alias<Value?>, onError: ((Error) -> Void)? = nil
 ) -> NominalContentModifier<Value> {
  NominalContentModifier(
   identifier: alias.identifier, enclosure: self, onError: onError
  )
 }
}

// MARK: Inlinable Structure
/// Content intended to reflect the structure of content
/// This is done with the ``EnumeratedContents`` of a structure
/// TODO: Interpret as folders with wrapped contents
public protocol StructuredContent: PublicContent // , RecursiveContent
{}

public extension StructuredContent {
 var id: String { _attributes.name }
 var _contents: [SomeContent] {
  Mirror(reflecting: self).children.compactMap { label, value in
   guard let label, label.hasPrefix("_"),
         let value = value as? any EnclosedContent else { return nil }
   return value
  }
 }
}

extension Content {
 var isStructured: Bool { self is any StructuredContent }
}

// MARK: Extensions
public extension Traits {
 static var observable: Self {
  var `self`: Self = .defaultValue
  self.isObservable = true
  return self
 }
}

// extension Optional: Sequence where Wrapped: ExpressibleAsEmpty & Sequence {
// public func makeIterator() -> Wrapped.Iterator {
//  (self ?? .empty).makeIterator()
// }
// }

extension String: StaticCodable {
 public static func encode(_ value: Self) throws -> Data {
  try value.data(
   using: .utf8, allowLossyConversion: false
  ).throwing(Error.encoding(Self.self))
 }

 public static func decode(_ data: Data) throws -> Self {
  try String(data: data, encoding: .utf8).throwing(Error.decoding(Self.self))
 }
}
