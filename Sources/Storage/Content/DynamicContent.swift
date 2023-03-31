import System
protocol DynamicContent: Content {
 var _traits: Traits? { get set }
 var _attributes: Attributes? { get set }
}

extension Content {
 var isDynamic: Bool { self is any DynamicContent }
}

extension DynamicContent {
 /// Changes the extension of a file based on `UTType` extension if it
 /// exists
 func type(_ type: UTType) -> Self {
  var `self` = self
  if self._traits == nil { self._traits = .defaultValue }
  self._traits!.utType = type
  return self
 }

 /// Sets the default permissions of a file
 func permissions(_ permissions: FilePermissions) -> Self {
  var `self` = self
  if self._attributes == nil { self._attributes = .defaultValue }
  self._attributes!.filePermissions = permissions
  return self
 }

 func observe(_ should: Bool = true) -> Self {
  var `self` = self
  if self._traits == nil { self._traits = .defaultValue }
  self._traits!.isObservable = should
  return self
 }

 func recursive(_ recurse: Bool = true) -> Self {
  var `self` = self
  if self._traits == nil { self._traits = .defaultValue }
  self._traits!.isRecursive = recurse
  return self
 }
}
