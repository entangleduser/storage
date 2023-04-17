import struct System.FilePermissions
public protocol DynamicContent: Content {
 var _attributes: Attributes { get set }
}

extension Content {
 var isDynamic: Bool { self is any DynamicContent }
}

public extension DynamicContent {
 @_disfavoredOverload
 var _attributes: Attributes {
  get { _reflection?.attributes ?? .defaultValue }
  nonmutating set {
   _reflection?.attributes = newValue
  }
 }

 func attributes<Value>(
  _ keyPath: WritableKeyPath<Attributes, Value>, _ value: Value
 ) -> Self {
  var `self` = self
  self._attributes[keyPath: keyPath] = value
  return self
 }

 func observe(_ should: Bool = true) -> Self { traits(\.isObservable, should) }
 func recursive(_ recurse: Bool = true) -> Self {
  traits(\.isRecursive, recurse)
 }

 /// Changes the extension of a file based on `UTType` extension if it
 /// exists
 func type(_ type: UTType) -> Self { traits(\.utType, type) }

 /// Sets the default permissions of a file
 func permissions(_ permissions: FilePermissions) -> Self {
  attributes(\.filePermissions, permissions)
 }

 func name(_ name: some LosslessStringConvertible) -> Self {
  attributes(\.name, name.description)
 }
}
