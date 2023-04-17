import Core
import Reflection
@_typeEraser(AnyContent)
public protocol Content: ReflectedContent, CustomStringConvertible {
 associatedtype Contents: Content
 @Storage.Contents var content: Contents { get }
 var _traits: Traits { get set }
}

public extension Content {
 var description: String { "\(Self.self)" }
 @_disfavoredOverload
 var _traits: Traits {
  get { _reflection?.traits ?? .defaultValue }
  nonmutating set {
   _reflection?.traits = newValue
  }
 }

 func traits<Value>(
  _ keyPath: WritableKeyPath<Traits, Value>, _ value: Value
 ) -> Self {
  var `self` = self
  self._traits[keyPath: keyPath] = value
  return self
 }
}

extension Content {
 @inlinable var metadata: StructMetadata { StructMetadata(type: Self.self) }
 @inlinable var info: TypeInfo { metadata.toTypeInfo() }
}

#if DEBUG
 extension Mirror.Children: CustomStringConvertible {
  public var description: String {
   map { label, value in
    """
    \(label == nil ? "_" :
     "var \(label!)"): \(type(of: value)) = \(String(describing: value).readable)
    """
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
#endif
