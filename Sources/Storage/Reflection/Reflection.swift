@_exported @testable import Composite
@_exported @testable import Extensions
@_exported @testable import Core
import System

final class Reflection: IndexedPropertyCache, Identifiable, Equatable {
 required init(
  _ publisher: AnyContentPublisher?,
  keyType: Any.Type,
  subjectType: Any.Type,
  index: ReflectionIndex
 ) {
  self.publisher = publisher
  self.keyType = keyType
  self.subjectType = subjectType
  self.index = index
 }

 let keyType: Any.Type
 var keyTypeID: ObjectIdentifier { ObjectIdentifier(keyType) }
 let subjectType: Any.Type
 var subjectTypeID: ObjectIdentifier { ObjectIdentifier(subjectType) }
 static func == (lhs: Reflection, rhs: Reflection) -> Bool { lhs.id == rhs.id }

 var mirror: ContentMirror? {
  get { publisher[mirror: keyType] }
  set { publisher[mirror: keyType] = newValue }
 }

 unowned var parent: Reflection?
 unowned var publisher: AnyContentPublisher!

 var index: ReflectionIndex

 var value: AnyContent {
  get { index.value }
  set { index.value = newValue }
 }

 var structure: (any EnclosedContent)?
 var onError: ((Error) -> Void)?
 var recoveryURL: URL?

 var isGroup: Bool { String.withName(for: subjectType) == "Group" }

 /// - note: contains a cache that stores values for non-mutating access
 var attributesCache =
  InheritedPropertyStorage<Attributes>(values: .defaultValue)
 var resourceCache =
  InheritedPropertyStorage<Resources>(values: .defaultValue)
 var traitsCache =
  InheritedPropertyStorage<Traits>(values: .defaultValue)
 var usedAttributes: Set<String> = .empty
 var usedResources: Set<String> = .empty
 var usedTraits: Set<String> = .empty

 var name: String? {
  didSet { updateName() }
 }

 func updateName() {
  // guard !_ignore else { return }
  guard let name else {
   `extension` = nil
   return
  }
  attributes.name = fileName(from: name)
  if let `extension` = fileExtension(from: name) {
   attributes.extension = `extension`
  }
 }

 var `extension`: String? {
  didSet { updateExtension() }
 }

 func updateExtension() {
  // guard !_ignore else { return }
  guard let `extension` else {
   attributes.extension = nil
   if let name {
    // remove extension
    attributes.name = fileName(from: name)
   }
   return
  }
  if let name = fileName(with: `extension`) {
   attributes.extension = self.extension
   self.name = name
  } else {
   self.extension = nil
  }
 }

 var path: String? {
  didSet {
   attributes.path = path
   // change names and set extensions, by default this will be set by the
   // result builder
  }
 }

 /// The cache for non-mutating access to wrapped values
 var cache: [String: () -> Any] = .empty
 /// Content types processed by this reflection
 var types: Set<String> = .empty

 deinit {
  print(
   """
   \(Self.self) was deallocated for \(subjectType)
   Publisher → \(publisher!)\nValue → \(index.value) with Index ⏎\n\(index)\n
   """
  )
 }

 @discardableResult func updateMirror() -> Bool {
  true
 }

 func setValues() {
  setResources()
  setAttributes()
 }

 func updateIfExisting() -> Bool {
  defer { print(index, terminator: "\n\n") }
  defer { publisher.objectWillChange.send() }
  if exists {
   if traits.isObservable {
    publisher.observe(self)
   }
   return true
  } else {
   // publisher.stopObserving(self)
   return false
  }
 }

 func update(_ mirror: ContentMirror) -> Bool {
  //  _ignore = true
  //  _publisher = publisher
  //  _keyType = keyType
  //  mirror.callAsFunction(index)
  //  mirror.reset()
  //  _ignore = false
  displayResources()
  displayAttributes()
  displayTraits()
  return updateIfExisting()
 }

 @discardableResult func update() -> Bool {
  if let mirror {
   return update(mirror)
  } else {
   return updateIfExisting()
  }
 }

 subscript<A: EnclosedContent>(_ structure: A) -> A.Value? {
  get {
   do {
    guard let _url else { return nil }
    return try structure.decode(Data(contentsOf: _url))
   } catch let error as Error {
    onError?(error)
    return nil
   } catch {
    onError?(.get(error))
    return nil
   }
  }
  set {
   do {
    defer { update() }
    guard let newValue else {
     try remove()
     return
    }
    try structure.encode(newValue).write(to: url, options: .atomic)
   } catch let error as Error {
    onError?(error)
   } catch {
    onError?(.set(error))
   }
  }
 }

 subscript<A>(type: A.Type) -> A? {
  get {
   do {
    guard let _url else { return nil }
    return try structure?.decode(any: Data(contentsOf: _url), as: A.self)
   } catch let error as Error {
    onError?(error)
    return nil
   } catch {
    onError?(.get(error))
    return nil
   }
  }
  set {
   do {
    defer { update() }
    try structure?
     .encode(any: newValue as Any)?.write(to: url, options: .atomic)
   } catch let error as Error {
    onError?(error)
   } catch {
    onError?(.set(error))
   }
  }
 }
}

// MARK: Values
extension Reflection {
 var traits: Traits {
  get { traitsCache.values.unsafelyUnwrapped }
  set {
   usedTraits.formUnion(Set(newValue.values.keys))
   traitsCache.values = newValue
  }
 }

 func resolveTraits() {
  if traitsCache.hasParent { traitsCache.converge() }
  if let utType = traitsCache[UTTypeKey.description] as? UTType {
   guard let `extension` = utType.preferredFilenameExtension
   else { fatalError("\(utType) has no value without an extension") }
   self.extension = `extension`
  }
  updatePath()
 }

 func displayTraits() {
  print(
   "\("★", color: .cyan, style: .bold)",
   traits.description,
   terminator: "\n\n"
  )
 }

 var resources: Resources {
  get { resourceCache.values.unsafelyUnwrapped }
  set {
   usedResources.formUnion(Set(newValue.values.keys))
   resourceCache.values = newValue
  }
 }

 var resourceValues: URLResourceValues? {
  get {
   try? url.resourceValues(
    forKeys: [
     .isDirectoryKey,
     .isHiddenKey,
     .isExecutableKey,
     .fileResourceTypeKey,
     .contentTypeKey,
     .localizedTypeDescriptionKey,
     .tagNamesKey
    ]
   )
  }
  set {
   guard let newValue else { return }
   var url = url
   try? url.setResourceValues(newValue)
  }
 }

 subscript(resource key: URLResourceKey) -> Any? {
  get { resourceValues?.allValues[key] }
  set {
   do {
    guard let newValue else {
     return
    }
    // this subscript will update the dynamic properties
    // while static properties can't be set
    switch key {
    case .isExecutableKey:
     guard let newValue = newValue as? Bool else { return }
     resources.isExecutable = newValue
     if newValue {
      attributes.filePermissions.formUnion(.ownerExecute)
     } else {
      attributes.filePermissions.remove(.ownerExecute)
     }
    default: break
    }
    // some values can be set using function while others can only be
    // read and cached
   }
  }
 }

 var isDirectory: Bool {
  (self[resource: .isDirectoryKey] as? Bool).unwrapped
 }

 var isHidden: Bool {
  (self[resource: .isHiddenKey] as? Bool).unwrapped
 }

 var isExecutable: Bool {
  self[resource: .isExecutableKey] as! Bool
 }

 var urlFileResourceType: URLFileResourceType? {
  self[resource: .fileResourceTypeKey] as? URLFileResourceType
 }

 var contentType: UTType? {
  guard let type = self[resource: .contentTypeKey] else {
   return nil
  }
  return type as? UTType
 }

 var contentDescription: String? {
  self[resource: .localizedTypeDescriptionKey] as? String
 }

 var tagNames: [String]? {
  self[resource: .tagNamesKey] as? [String]
 }

 func updateResources() {
  guard let values = resourceValues else { return }
  resources[any: DirectoryKey()] = values.isDirectory as Any
  resources[any: HiddenKey()] = values.isHidden as Any
  resources[any: ExecutableKey()] = isExecutable as Any
  resources[any: URLFileResourceTypeKey()] = values.fileResourceType as Any
  resources[any: TypeIdentifierKey()] = values.contentType as Any
  resources[any: TypeDescriptionKey()] = values.localizedTypeDescription as Any
  resources[any: TagNamesKey()] = values.tagNames as Any
 }

 func setResources() {
  updateResources()
  for keyDescription in usedResources {
   guard let value = resourceCache[keyDescription],
         let fileKey = urlResourceKey(for: keyDescription) else { continue }
   self[resource: fileKey] = value
  }

  // displayResources()
 }

 func displayResources() {
  print(
   "\("⚑", color: .cyan, style: .bold)",
   resources.description,
   terminator: "\n\n"
  )
 }

 func urlResourceKey(for string: String) -> URLResourceKey? {
  switch string {
  case DirectoryKey.description: return .isDirectoryKey
  case HiddenKey.description: return .isHiddenKey
  case ExecutableKey.description: return .isExecutableKey
  case URLFileResourceTypeKey.description: return .fileResourceTypeKey
  case TypeIdentifierKey.description: return .contentTypeKey
  case TypeDescriptionKey.description: return .localizedTypeDescriptionKey
  case TagNamesKey.description: return .tagNamesKey
  default: return nil
  }
 }

 var attributes: Attributes {
  get { attributesCache.values.unsafelyUnwrapped }
  set {
   usedAttributes.formUnion(Set(newValue.values.keys))
   // if update() {
   attributesCache.values = newValue
   // }
  }
 }

 var fileAttributes: [FileAttributeKey: Any]? {
  try? publisher.attributesOfItem(atPath: url.path)
 }

 subscript(attribute key: FileAttributeKey) -> Any? {
  get { try? publisher.attributesOfItem(atPath: url.path)[key] }
  set {
   do {
    guard let newValue else {
     try publisher
      .setAttributes([key: newValue as Any], ofItemAtPath: url.path)
     return
    }
    try publisher
     .setAttributes([key: newValue], ofItemAtPath: url.path)
   } catch {
    onError?(.setAttribute(key))
   }
  }
 }

 func fileAttributeKey(for string: String) -> FileAttributeKey? {
  switch string {
  case FileNumberKey.description: return .systemFileNumber
  case ExtensionHiddenKey.description: return .extensionHidden
  case FilePermissionsKey.description: return .posixPermissions
  case DateCreatedKey.description: return .creationDate
  case DateModifiedKey.description: return .modificationDate
  case FileSizeKey.description: return .size
  default: return nil
  }
 }

 func setAttributes() {
  guard exists else { return }
  for keyDescription in usedAttributes {
   guard let value = attributesCache[keyDescription],
         let fileKey = fileAttributeKey(for: keyDescription) else { continue }
   self[attribute: fileKey] = value
  }
  path = _path
  // displayAttributes()
 }

 func displayAttributes() {
  print(
   "\("✦", color: .cyan, style: .bold)",
   attributes.description,
   terminator: "\n\n"
  )
 }

 var number: Int? { self[attribute: .systemFileNumber] as? Int }
 var size: Int? { self[attribute: .size] as? Int }
 var hiddenExtension: Bool? { self[attribute: .extensionHidden] as? Bool }
 var filePermissions: FilePermissions {
  self[attribute: .posixPermissions] as? FilePermissions ?? .empty
 }

 var creationDate: Date? { self[attribute: .creationDate] as? Date }
 var modificationDate: Date? { self[attribute: .modificationDate] as? Date }

 func displayFileAttributes() {
  print(
   "\n⌘ \("FileAttributes", color: .green)",
   " Number: Int = " + String(describing: number.unwrapped),
   " ByteSize: Int = " + String(describing: size.unwrapped),
   " HiddenExtension: Bool = " + String(describing: hiddenExtension.unwrapped),
   " Created: Date = " + String(describing: creationDate.unwrapped),
   " Modified: Date = " + String(describing: modificationDate.unwrapped),
   separator: .newline, terminator: "\n\n"
  )
 }
}

// MARK: Observation
extension Reflection {
 var observationHandler: DispatchWorkItem {
  DispatchWorkItem(qos: .userInteractive, block: didChange)
 }

 func didChange() {
  defer { publisher.objectWillChange.send() }
  if exists {
   if traits.isObservable {
    publisher.observe(self)
   }
   setValues()
  } else {
   // publisher.stopObserving(self)
  }
 }
}

// MARK: Filters
extension Reflection {
 /// types that can be filtered for recursing the content structure
 static var types: Set<String> {
  ["Folder", "ForEach", "CodableContentModifier", "BufferModifier"]
 }

 static var properties: Set<String> { ["AttributeProperty"] }
 static var filterCount: Int { types.count + properties.count }
}

// MARK: Properties
extension Reflection {
 var directory: URL {
  do {
   return parent == nil ? try publisher.contentURL() : parent!._url!
  } catch {
   onError?(.url(error))
   fatalError()
  }
 }

 func createContentURL() {
  do {
   var isDirectory: ObjCBool = false
   if publisher.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
    if isDirectory.boolValue {
     //
    } else {
     fatalError()
    }
   } else {
    try publisher
     .createDirectory(at: directory, withIntermediateDirectories: true)
    // print("Created folder at \"\(directory.path)\"")
   }
  } catch {
   onError?(.url(error))
   fatalError()
  }
 }

 @discardableResult func updatePath() -> String {
  var base = directory
  guard let name = name?.wrapped else { return base.path }
  base.appendPathComponent(name)
  path = base.path
  return base.path
 }

 var _path: String {
  if let path { return path } else {
   return updatePath()
  }
 }

 var _url: URL? { URL(fileURLWithPath: _path) }

 func createDirectory() {
  guard let _url else { return }
  do {
   var isDirectory: ObjCBool = false
   if publisher.fileExists(atPath: _path, isDirectory: &isDirectory) {
    if isDirectory.boolValue {
     //
    } else {
     fatalError()
    }
   } else {
    try publisher.createDirectory(at: _url, withIntermediateDirectories: true)
    // print("Created folder at \"\(directory.path)\"")
   }
  } catch {
   onError?(.url(error))
   fatalError("\(error)")
  }
 }

 /// Returns a `URL` and creates the content folder if needed
 var url: URL {
  createContentURL()
  var base = directory
  guard let name = name?.wrapped else { return base }
  base.appendPathComponent(name)
  return base
 }

 var exists: Bool { publisher.fileExists(atPath: _path) }

 func delete() throws {
  guard let _url else { return }
  try publisher.removeItem(at: _url)
 }

 func trash() throws {
  guard let _url else { return }
  var destination: NSURL?
  try publisher.trashItem(at: _url, resultingItemURL: &destination)
  if let destination { recoveryURL = destination as URL }
 }

 func remove() throws {
  if traits.removalMethod == .delete {
   try delete()
  } else {
   try trash()
  }
 }

 func create() {
  guard let structure else { fatalError() }
  guard mirror == nil else { return }
  do {
   if !exists { try structure.create() }
  } catch let error as Error {
   onError?(error)
  } catch {
   onError?(.create(error))
  }
 }

 func fileName(from name: String) -> String {
  guard let splitIndex = name.lastIndex(of: .period) else { return name }
  return String(name[name.startIndex ..< splitIndex])
 }

 func fileExtension(from name: String) -> String? {
  guard let startIndex = name.lastIndex(of: .period),
        startIndex != name.startIndex
  else { return nil }
  return String(name[name.index(after: startIndex) ..< name.endIndex])
 }

 func fileName(with extension: String) -> String? {
  var `extension` = `extension`
  if `extension`.first == .period { `extension`.removeFirst() }
  guard !`extension`.isEmpty, let name else { return nil }
  // check for existing extension and modify if it's not the name itself
  if let splitIndex =
   name.lastIndex(of: .period), splitIndex != name.startIndex {
   return
    String(name[name.startIndex ..< splitIndex]) + .period + `extension`
  } else {
   return name + .period + `extension`
  }
 }
}

extension Reflection {
 func set<A: ExpressibleByNilLiteral>(
  _ newValue: A,
  id: some LosslessStringConvertible
 ) {
  // defer { name = nil }
  name = id.description
  resolveTraits()
  self[A.self] = newValue
 }

 func get<A: ExpressibleByNilLiteral>(
  id: some LosslessStringConvertible, as type: A.Type
 ) -> A {
  // defer { name = nil }
  name = id.description
  resolveTraits()
  return self[A.self] ?? nil
 }
}

// extension Reflection {
// func set<A: ExpressibleByNilLiteral & Sequence>(
//  _ newValue: A,
//  id: some LosslessStringConvertible
// ) {
//   //defer { name = nil }
//  self.name = id.description
//  self[A.self] = newValue
// }
// func get<A: ExpressibleByNilLiteral & Sequence>(
//  id: some LosslessStringConvertible, as type: A.Type
// ) -> A {
//   //defer { name = nil }
//  self.name = id.description
//  return self[A.self] ?? nil
// }
// }
