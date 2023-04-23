@_exported import Composite
public protocol AttributeKey: ResolvedKey {}

public struct PathKey: AttributeKey, OptionalKey {
 public typealias Value = String
}

public struct NameKey: AttributeKey, DefaultKey {
 public typealias Value = String
}

public struct ExtensionKey: AttributeKey, OptionalKey {
 public typealias Value = String
}

public struct FileNumberKey: AttributeKey, OptionalKey {
 public typealias Value = Int
}

public struct FileSizeKey: AttributeKey, DefaultKey {
 public static let defaultValue: Int = .zero
}

public struct ExtensionHiddenKey: AttributeKey, IntBoolKey {}

import struct System.FilePermissions
import struct System.CModeT
public struct FilePermissionsKey: AttributeKey, ResolvedKey {
 public static func resolveValue(_ value: CModeT?) -> FilePermissions {
  guard let value else { return .empty }
  return FilePermissions(rawValue: value)
 }

 public static func storeValue(_ value: FilePermissions?) -> CModeT? {
  guard let value else { return nil }
  return value.rawValue
 }
}

public struct DateCreatedKey: AttributeKey, DoubleDateKey {}
public struct DateModifiedKey: AttributeKey, DoubleDateKey {}
public struct DateAddedKey: AttributeKey, DoubleDateKey {}

// MARK: Attributes
public struct Attributes: KeyValues {
 public init() {}
 public var values: [String: Any] = .empty
 public static var defaultValues: OrderedDictionary<String, Any> {
  [
   PathKey.description: PathKey.resolvedValue as Any,
   NameKey.description: NameKey.defaultValue,
   ExtensionKey.description: ExtensionKey.resolvedValue as Any,
   FileNumberKey.description: FileNumberKey.resolvedValue as Any,
   FilePermissionsKey.description: FilePermissionsKey.resolvedValue,
   FileSizeKey.description: FileSizeKey.defaultValue,
   ExtensionHiddenKey.description: ExtensionHiddenKey.resolvedValue as Any,
   DateCreatedKey.description: DateCreatedKey.resolvedValue as Any,
   DateModifiedKey.description: DateModifiedKey.resolvedValue as Any,
   DateAddedKey.description: DateAddedKey.resolvedValue as Any
  ]
 }
}

public extension Attributes {
 var path: String? {
  get { self[PathKey.self] }
  set { self[PathKey.self] = newValue }
 }

 var name: String {
  get { self[NameKey.self] }
  set { self[NameKey.self] = newValue }
 }

 var `extension`: String? {
  get { self[ExtensionKey.self] }
  set { self[ExtensionKey.self] = newValue }
 }

 var fileNumber: Int? {
  get { self[FileNumberKey.self] }
  set { self[FileNumberKey.self] = newValue }
 }

 var filePermissions: FilePermissions {
  get { self[FilePermissionsKey.self] }
  set { self[FilePermissionsKey.self] = newValue }
 }

 var fileSize: Int {
  get { self[FileSizeKey.self] }
  set { self[FileSizeKey.self] = newValue }
 }

 var extensionHidden: Bool {
  get { self[ExtensionHiddenKey.self] }
  set { self[ExtensionHiddenKey.self] = newValue }
 }

 var dateCreated: Date? {
  get { self[DateCreatedKey.self] }
  set { self[DateCreatedKey.self] = newValue }
 }

 var dateModified: Date? {
  get { self[DateModifiedKey.self] }
  set { self[DateModifiedKey.self] = newValue }
 }

 var dateAdded: Date? {
  get { self[DateAddedKey.self] }
  set { self[DateAddedKey.self] = newValue }
 }
}
