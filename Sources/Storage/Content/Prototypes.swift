protocol OptionalNameConvertible {
 var name: String? { get }
}

extension OptionalNameConvertible {
 var name: String? { "\(Self.self)" }
}

/// A strict or syntactic content type that identifies the content by name
protocol IdentifiableContent: Content {
 associatedtype ID: LosslessStringConvertible
 var id: ID { get }
}

extension Content {
 var isIdentifiable: Bool { Self.self is any IdentifiableContent.Type }
}

protocol VariadicContent: DynamicContent {
 var _contents: [AnyContent] { get }
}

extension Content {
 var isVariadic: Bool { Self.self is any VariadicContent.Type }
}

protocol RecursiveContent:
DynamicContent, VariadicContent, IdentifiableContent {}

extension Content {
 var isRecursive: Bool { Self.self is any RecursiveContent.Type }
}
