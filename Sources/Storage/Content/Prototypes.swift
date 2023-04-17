/// A strict or syntactic content type that identifies the content by name
public protocol IdentifiableContent: Content {
 associatedtype ID: LosslessStringConvertible
 var id: ID { get }
}

extension Never: LosslessStringConvertible {
 public init?(_ description: String) { fatalError() }
}

extension Content {
 var isIdentifiable: Bool { self is any IdentifiableContent }
}

public protocol VariadicContent: DynamicContent {
 var _contents: [SomeContent] { get }
}

extension Content {
 var isVariadic: Bool { self is any VariadicContent }
}

public protocol RecursiveContent: VariadicContent, IdentifiableContent {}

extension Content {
 var isRecursive: Bool { self is any RecursiveContent }
}
