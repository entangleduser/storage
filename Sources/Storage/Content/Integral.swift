// MARK: Base Types
public extension Content where Contents == Never {
 var content: Never { fatalError() }
}

extension Never: Content {
 public typealias Contents = Never
}

/// `Content` that doesn't get rendered
/// - Note: `Self.Contents` is ``Never``
public struct EmptyContent: Content { public init() {} }

// MARK: Wrapped Types
public protocol WrappedContent: Content {
 associatedtype Wrapped
 var wrappedContent: Wrapped { get }
}

extension Content {
 var unwrapped: SomeContent {
  if let self = self as? any WrappedContent {
   return self.wrappedContent as! SomeContent
  } else {
   return self
  }
 }
}

extension Content {
 var isArray: Bool { self is [SomeContent] }
}

extension Content {
 var isEmptyContent: Bool { self is EmptyContent }
 var hasContents: Bool {
  !(Contents.self is Never.Type) &&
   !(Contents.self is EmptyContent.Type)
 }
}

public typealias SomeContent = any Content

public struct AnyContent: WrappedContent {
 public let wrappedContent: SomeContent

 public init(erasing content: some Content) {
  self.wrappedContent = content.unwrapped
 }

 public init(_ value: some Content) { self.init(erasing: value) }
}

extension [SomeContent]: ReflectedContent {}
extension [SomeContent]: Content {}

// TODO: Update contained reflection on changes to the condition
public struct ConditionalContent<A, B>: WrappedContent
where A: Content, B: Content {
 enum Storage {
  case trueContent(A)
  case falseContent(B)
 }

 let storage: Storage

 public var wrappedContent: SomeContent {
  switch storage {
  case let .trueContent(content): return content.unwrapped
  case let .falseContent(content): return content.unwrapped
  }
 }
}

extension Optional: ReflectedContent where Wrapped: ReflectedContent {
 public var _reflection: Reflection? {
  get {
   if let content = self { return content._reflection }
   else { return nil }
  }
  set {
   if var content = self {
    content._reflection = newValue
    self = content
   }
  }
 }
}

extension Optional: Content where Wrapped: Content {}

extension Optional: WrappedContent where Wrapped: WrappedContent {
 public var wrappedContent: SomeContent {
  if let content = self { return content }
  else { return EmptyContent() }
 }
}

// MARK: - Integral
/// Content that can be modified but the attributes are projected
/// Enumerated must have a binding with filter (for determining attributes)
/// Different ``EnumeratedContents`` types bind to different kinds of structures
/// but the initial input is usually `Data`
/// The reflection should be cached to contain inner reflections that reflect
/// the parameters for enumerating contents
public protocol EnumeratedContents: DynamicContent {
 associatedtype Value
 var wrappedValue: [Value] { get nonmutating set }
}

extension Content {
 var isEnumerated: Bool { self is any EnumeratedContents }
}

// MARK: Codable
/// An object that represents the encoded bits of a value through an encoder
public protocol EncodableContent: EnclosedContent
where Value: Encodable, Encoder.Output == Data {
 associatedtype Encoder: TopLevelEncoder
 var encoder: Encoder { get }
}

/// An object that represents a decoded value from a decoder
public protocol DecodableContent: EnclosedContent
where Value: Decodable, Decoder.Input == Data {
 associatedtype Decoder: TopLevelDecoder
 var decoder: Decoder { get }
}

public extension EncodableContent {
 func encode(_ value: Value) throws -> Data { try encoder.encode(value) }
}

public extension DecodableContent {
 func decode(_ data: Data) throws -> Value {
  try decoder.decode(Value.self, from: data)
 }
}

public typealias CodableContent = EncodableContent & DecodableContent

extension EnclosedContent
where Value: AutoEncodable, Value.AutoEncoder.Output == Data {
 func encode(_ value: Value) throws -> Data { try value.encoded() }
}

extension EnclosedContent
where Value: AutoDecodable, Value.AutoDecoder.Input == Data {
 func decode(_ data: Data) throws -> Value {
  try Value.decoder.decode(Value.self, from: data)
 }
}

extension Content {
 var isEncodable: Bool { Self.self is any EncodableContent.Type }
 var isDecodable: Bool { Self.self is any DecodableContent.Type }
 var isCodable: Bool { Self.self is any CodableContent.Type }
}

/// Accessing the content outside of the structure to manipulate it without sending the
/// specific path
extension Never: TopLevelDecoder {
 public func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable {
  fatalError()
 }
}

extension Never: TopLevelEncoder {
 public func encode(_ value: some Encodable) throws -> Data { fatalError() }
}

public extension AutoDecodable where Self.AutoDecoder == Never {
 static var decoder: Never { fatalError() }
 init(from decoder: Decoder) throws { fatalError() }
}

public extension AutoEncodable where Self.AutoEncoder == Never {
 static var encoder: Never { fatalError() }
 func encode(to encoder: Encoder) throws { fatalError() }
}
