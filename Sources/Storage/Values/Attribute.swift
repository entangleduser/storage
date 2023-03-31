@_exported @testable import Composite
protocol AttributeKey: ResolvedKey {}

struct PathKey: AttributeKey, OptionalKey {
 typealias Value = String
}

struct NameKey: AttributeKey, DefaultKey {
 typealias Value = String
}

struct ExtensionKey: AttributeKey, OptionalKey {
 typealias Value = String
}

struct FileNumberKey: AttributeKey, OptionalKey {
 typealias Value = Int
}

struct FileSizeKey: AttributeKey, DefaultKey {
 static let defaultValue: Int = .zero
}

struct ExtensionHiddenKey: AttributeKey, IntBoolKey {}

import System
struct FilePermissionsKey: AttributeKey, ResolvedKey {
 static func resolveValue(_ value: CModeT?) -> FilePermissions {
  guard let value else { return .empty }
  return FilePermissions(rawValue: value)
 }

 static func storeValue(_ value: FilePermissions?) -> CModeT? {
  guard let value else { return nil }
  return value.rawValue
 }
}

struct DateCreatedKey: AttributeKey, DoubleDateKey {}
struct DateModifiedKey: AttributeKey, DoubleDateKey {}
struct DateAddedKey: AttributeKey, DoubleDateKey {}

extension Attributes {
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
