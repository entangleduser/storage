@_exported @testable import Core
import Reflection
protocol Content: ReflectedContent, CustomStringConvertible {
 associatedtype Contents: Content
 @Storage.Contents var content: Contents { get }
}

extension Mirror.Children: CustomStringConvertible {
 public var description: String {
  map { label, value in
   "\(label == nil ? "_" : "var \(label!)"): \(type(of: value)) = \(value)"
  }
  .joined(separator: "\n")
 }
}

func recursiveMirror(_ value: Any, perform: @escaping (Mirror) -> Void) {
 let mirror = Mirror(reflecting: value)
 perform(mirror)
 mirror.children.forEach { _, value in
  recursiveMirror(value, perform: perform)
 }
}

func recursiveView(for value: Any) -> String {
 let mirror = Mirror(reflecting: value)
 return
  """
  \(mirror.subjectType)
  \(mirror.children.description)
  """
}

extension Content {
 public var description: String { "\(Self.self)" }
}

/// `Content` that doesn't get rendered
struct EmptyContent: Content {}

protocol WrappedContent: Content {
 var wrappedContent: AnyContent { get }
}

typealias AnyWrappedContent = any WrappedContent
extension Content {
 var unwrapped: AnyContent {
  if let self = self as? AnyWrappedContent {
   return self.wrappedContent
  } else {
   return self
  }
 }
}

extension Content {
 var isArray: Bool { self is [AnyContent] }
}

extension Content {
 var isEmptyContent: Bool { self is EmptyContent }
 var hasContents: Bool {
  !(Contents.self is Never.Type) &&
   !(Contents.self is EmptyContent.Type)
 }
}

extension Content {
 @inlinable var metadata: StructMetadata { StructMetadata(type: Self.self) }
 @inlinable var info: TypeInfo { metadata.toTypeInfo() }
}
