/// An object that represents the encoded bits of a value through an encoder
protocol EncodableContent: EnclosedContent
where Value: Encodable, Encoder.Output == Data {
 associatedtype Encoder: TopLevelEncoder
 var encoder: Encoder { get }
}

/// An object that represents a decoded value from a decoder
protocol DecodableContent: EnclosedContent
where Value: Decodable, Decoder.Input == Data {
 associatedtype Decoder: TopLevelDecoder
 var decoder: Decoder { get }
}

extension EncodableContent {
 func encode(_ value: Value) throws -> Data { try encoder.encode(value) }
}

extension DecodableContent {
 func decode(_ data: Data) throws -> Value { try decoder.decode(Value.self, from: data) }
}

typealias CodableContent = EncodableContent & DecodableContent

extension Content {
 var isEncodable: Bool { Self.self is any EncodableContent.Type }
 var isDecodable: Bool { Self.self is any DecodableContent.Type }
 var isCodable: Bool { Self.self is any CodableContent.Type }
}

extension DecodableContent {
// @Storage.Contents
// func throwing(_ handler: @escaping (Any) -> ()) -> some Content {
//  self
// }
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
