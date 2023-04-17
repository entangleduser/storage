#if canImport(SwiftUI)
 @_exported import struct SwiftUI.Binding
 @_exported import protocol SwiftUI.DynamicProperty
#else
 /// - Parameters: Create bindings for non SwiftUI integration
 public protocol DynamicProperty {
  /// Updates the underlying value of the stored value.
  mutating func update()
 }
#endif
