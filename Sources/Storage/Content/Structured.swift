@_exported @testable import Composite
extension Traits {
 static var observable: Self {
  var `self`: Self = .defaultValue
  self.isObservable = true
  return self
 }
}

protocol NominalContent: DynamicContent, IdentifiableContent {
 associatedtype Value
 var defaultValue: Value? { get set }
 override var id: ID { get set }
 init()
}

extension NominalContent {
 init(_ value: Value? = nil) {
  self.init()
  self.defaultValue = value
 }

 static func ?? (lhs: Self, rhs: Value) -> Self {
  if nil ~= lhs.defaultValue { return lhs }
  else {
   var copy = lhs
   copy.defaultValue = rhs
   return copy
  }
 }
}

extension NominalContent where Value: Infallible {
 init() {
  self.init()
  self.defaultValue = .defaultValue
 }
}

// MARK: Dynamic Content Structures
// Content that can be encoded and decoded, as well as modified to provide access to the
// structure
protocol EnclosedContent: NominalContent {
 associatedtype Value
 var _reflection: Reflection? { get set }
 var defaultValue: Value? { get set }
 mutating func update(_ reflection: Reflection)
 func decode(_ data: Data) throws -> Value
 @discardableResult
 func encode(_ value: Value) throws -> Data
 func get() -> Value?
 func set(_ newValue: Value?)
 func create() throws
}

extension EnclosedContent {
 func decode(_ data: Data) throws -> Value { defaultValue.unsafelyUnwrapped }
 func encode(_ value: Value) throws -> Data { Data() }
 var traits: Traits { _traits ?? .defaultValue }
 var attributes: Attributes { _attributes ?? .defaultValue }
 mutating func update(_ reflection: Reflection) {
  _reflection = reflection
  reflection.structure = self
  if let _traits {
   self._traits = reflection.traits.merging(with: _traits)
   reflection.traits = self._traits!
  }

  if traits.utType != nil, let name = id.description.wrapped {
   reflection.name = name
  } else {
   reflection.name = id.description
  }

  reflection.resolveTraits()

  reflection.create()

  if let _attributes {
   // reflection.attributesCache.converge()
   self._attributes = reflection.attributes.merging(with: _attributes)
   reflection.attributes = self._attributes!
  }

  reflection.setAttributes()
 }

 func encode(any value: Any) throws -> Data? {
  guard let newValue = value as? Value? else {
   throw Error.decoding(Swift.type(of: value), reason: "bad format")
  }
  guard let newValue else {
   try _reflection?.remove()
   return nil
  }
  return try encode(newValue)
 }

 func decode<A>(any data: Data, as: A.Type) throws -> A? {
  try decode(data) as? A
 }

 func get() -> Value? { _reflection?[self] }
 func set(_ newValue: Value?) { _reflection?[self] = newValue }
 @inlinable func set<A>(any newValue: A?) {
  _reflection?[A.self] = newValue
 }

 func create() throws {
  guard let _reflection, let publisher = _reflection.publisher else { return }
  do {
   if traits.createMethod == .automatic,
      !_reflection.exists, let defaultValue {
    try publisher.createFile(
     atPath: _reflection.url.path, contents: encode(defaultValue)
    )
   }
  } catch let error as Error {
   _reflection.onError?(error)
  } catch {
   _reflection.onError?(.set(error))
  }
 }
}

extension EncodableContent where Value: Infallible {
 func decode(_ data: Data) throws -> Value { defaultValue.unwrapped }
}

extension EncodableContent where Value: AutoCodable {
 func decode(_ data: Data) throws -> Value {
  try Value.decoder.decode(Value.self, from: data)
 }

 func encode(_ value: Value) throws -> Data { try value.encoded() }
}

extension SelfCodable where Self: AutoCodable {
 func decode(_ data: Data) throws -> Self {
  try Self.decoder.decode(Self.self, from: data)
 }

 func encode(_ value: Self) throws -> Data { try value.encoded() }
}

struct Structure
<Value: Codable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder>: CodableContent
where Encoder.Output == Data, Decoder.Input == Data {
 var id: String = .empty
 unowned var _reflection: Reflection?
 var _traits: Traits? = .observable
 var _attributes: Attributes?
 var defaultValue: Value?
 var encoder: Encoder
 var decoder: Decoder
 @_disfavoredOverload
 init() { fatalError("A decoder/encoder is needed to initialize \(Self.self)") }
}

extension Structure where Encoder == JSONEncoder, Decoder == JSONDecoder {
 init(_ name: some LosslessStringConvertible, default value: Value? = nil) {
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

extension Structure
where Value: Infallible, Encoder == JSONEncoder, Decoder == JSONDecoder {
 /// The property can be set to nil to reflect changes
 init(
  _ name: some LosslessStringConvertible, default value: Value = .defaultValue
 ) {
  self.id = name.description
  self.defaultValue = value
  self.encoder = JSONEncoder()
  self.decoder = JSONDecoder()
 }
}

extension Structure
 where Value: AutoCodable,
 Encoder == Value.AutoEncoder, Decoder == Value.AutoDecoder {
 /// The property can be set to nil to reflect changes
 init(_ name: some LosslessStringConvertible, default value: Value? = nil) {
  self.id = name.description
  self.defaultValue = value
  self.encoder = Value.encoder
  self.decoder = Value.decoder
 }
}

extension Structure
 where Value: AutoCodable & Infallible,
 Encoder == Value.AutoEncoder, Decoder == Value.AutoDecoder {
 /// The placeholder can be modified to change the reflection and update bindings
 init(
  _ name: some LosslessStringConvertible, default value: Value = .defaultValue
 ) {
  self.id = name.description
  self.defaultValue = value
  self.encoder = Value.encoder
  self.decoder = Value.decoder
 }
}

extension Content {
 typealias JSON<Value> =
  Structure<Value, JSONEncoder, JSONDecoder> where Value: Codable
 typealias Auto<Value> =
  Structure<Value, Value.AutoEncoder, Value.AutoDecoder>
   where Value: AutoCodable
}

struct NominalStructure<Value: SelfCodable>: EnclosedContent, NominalContent {
 init() {}
 unowned var _reflection: Reflection?
 var _traits: Traits? = .observable
 var _attributes: Attributes?
 var id: String = .empty
 var defaultValue: Value?
 func decode(_ data: Data) throws -> Value { try Value.decode(data) }
 func encode(_ value: Value) throws -> Data { try Value.encode(value) }
}

extension NominalStructure {
 /// The property can be set to nil to reflect changes
 init(_ name: some LosslessStringConvertible, default value: Value? = nil) {
  self.id = name.description
  self.defaultValue = value
 }
}

extension Content {
 typealias Nominal<Value> = NominalStructure<Value>
  where Value: Sequence & SelfCodable
}

extension Optional: Sequence where Wrapped: ExpressibleAsEmpty & Sequence {
 public func makeIterator() -> Wrapped.Iterator {
  (self ?? .empty).makeIterator()
 }
}

protocol SelfCodable {
 static func encode(_ value: Self) throws -> Data
 static func decode(_ data: Data) throws -> Self
}

extension String: SelfCodable {
 static func encode(_ value: Self) throws -> Data {
  // guard let value else { return Data() }
  try value.data(
   using: .utf8, allowLossyConversion: false
  ).throwing(Error.encoding(Self.self))
 }

 static func decode(_ data: Data) throws -> Self {
  try String(data: data, encoding: .utf8).throwing(Error.decoding(Self.self))
 }
}

// MARK: Structured Content Modifiers
/// A modifier for `EnclosedContent`, or content that can be encoded and decoded
protocol StructureModifier: AttributeModifier, DynamicContent
where Enclosure: EnclosedContent, Value == Enclosure.Value {
 var alias: Alias<Value?> { get set }
 var enclosure: Enclosure { get set }
 var onError: ((Error) -> Void)? { get }
 mutating func update(_ reflection: Reflection)
}

extension StructureModifier {
 unowned var _reflection: Reflection? {
  get { alias._reflection }
  set { alias._reflection = newValue }
 }

 mutating func update(_ reflection: Reflection) {
  if let _traits { reflection.traits.merge(with: _traits) }
  if let _attributes { reflection.attributes.merge(with: _attributes) }
  reflection.onError = onError
  enclosure.update(reflection)
  reflection.structure = enclosure
  _reflection = reflection
  if reflection.mirror == nil {
   alias.update()
  }
 }
}

struct CodableContentModifier<
 Value: Codable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder
>: StructureModifier
where Encoder.Output == Data, Decoder.Input == Data {
 typealias Enclosure = Structure<Value, Encoder, Decoder>
 var _traits: Traits? = .observable
 var _attributes: Attributes?
 var alias: Alias<Value?>
 var enclosure: Structure<Value, Encoder, Decoder>
 let onError: ((Error) -> Void)?
}

extension Structure {
 func alias(
  _ alias: Alias<Value?>, onError: ((Error) -> Void)? = nil
 ) -> CodableContentModifier<Value, Encoder, Decoder> {
  CodableContentModifier(
   alias: alias,
   enclosure: self, onError: onError
  )
 }
}

struct BufferModifier<Value: Sequence & SelfCodable>: StructureModifier {
 typealias Enclosure = NominalStructure<Value>
 var _traits: Traits? = .observable
 var _attributes: Attributes?
 var alias: Alias<Value?>
 var enclosure: NominalStructure<Value>
 let onError: ((Error) -> Void)?
}

extension NominalStructure where Value: Sequence {
 func alias(
  _ alias: Alias<Value?>, onError: ((Error) -> Void)? = nil
 ) -> BufferModifier<Value> {
  BufferModifier(
   alias: alias,
   enclosure: self, onError: onError
  )
 }
}

/*
 // MARK: Wrappers for folder/value based content structures
 /// A nominal property that can reflect it's attributes and values
 /// - Example
 /// struct Clip<ID: LosslessStringConvertible>: Content {
 /// let id: ID
 /// // contents directly encoded as seperate files
 /// @Buffered var message: String?
 /// @Buffered var audio: [Float]?
 /// init(_ name: ID, message: String, audio: [Float]? = nil) {
 /// self.id = name
 /// self.message = message
 /// self.audio = audio
 /// }
 /// }
 // TODO: Realize the struct metadata that determines the file name
 protocol ContentProperty: ReflectedProperty {
  associatedtype Value
 }

 extension ContentProperty {
  func update() {}
 }

 @propertyWrapper
 struct StructuredContentProperty
 <Value: Codable>: ContentProperty {
  unowned var _reflection: Reflection?
  var defaultValue: Value? = nil
  var wrappedValue: Value? {
   get { defaultValue }
   nonmutating set {}
  }
 }

 @propertyWrapper
 struct BufferedContentProperty
 <Value: Sequence & Codable>: ContentProperty {
  unowned var _reflection: Reflection?
  var defaultValue: Value? = nil
  var wrappedValue: Value? {
   get { defaultValue }
   nonmutating set {}
  }
 }

 extension Content {
  typealias Structured<Value> = StructuredContentProperty<Value>
   where Value: Codable
  typealias Buffered<Value> = BufferedContentProperty<Value>
   where Value: Sequence & Codable
 }
 */
