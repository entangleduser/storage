import Composite
import Extensions
import Core
import struct System.FilePermissions

public class Reflection: IndexedPropertyCache, Identifiable, Equatable {
 public static func == (lhs: Reflection, rhs: Reflection) -> Bool {
  lhs.id == rhs.id
 }

 required init(
  _ publisher: AnyContentPublisher?,
  key: AnyHashable?,
  keyType: Any.Type,
  subjectType: Any.Type,
  index: ReflectionIndex
 ) {
  self.key = key
  self.publisher = publisher
  self.keyType = keyType
  self.subjectType = subjectType
  self.index = index
 }

 var key: AnyHashable?
 let keyType: Any.Type
 var keyTypeID: ObjectIdentifier { ObjectIdentifier(keyType) }
 let subjectType: Any.Type
 var subjectTypeID: ObjectIdentifier { ObjectIdentifier(subjectType) }

 var mirror: ContentMirror? {
  get { publisher[cached: key, for: keyType] }
  set { publisher[cached: key, for: keyType] = newValue }
 }

 unowned var parent: Reflection?
 unowned var publisher: AnyContentPublisher!
 public var index: ReflectionIndex
 func updateIndex() {
  defer { publisher.objectWillChange.send() }
  guard !publisher.ignore else { return }
  mirror.unsafelyUnwrapped.callAsFunction(index)
 }

 var value: SomeContent {
  get { index.value }
  set { index.value = newValue }
 }

 var structure: (any EnclosedContent)?
 var contents: [AnyHashable: any EnclosedContent] = .empty
 var onError: ((Error) -> Void)?
 var recoveryURL: URL?

 // var isGroup: Bool { String.withName(for: subjectType) == "Group" }

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

 func setValues() {
  setResources()
  setAttributes()
 }

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
 public var cache: [String: () -> Any] = .empty
 /// Content types processed by this reflection
 public var types: Set<String> = .empty

 deinit {
  log(
   """
   \(Self.self) was deallocated for \(subjectType)
   Publisher → \(publisher!)\nValue → \(index.value) with Index ⏎\n\(index)\n
   """,
   for: .reflection
  )
 }

 @discardableResult
 func updateIfExisting() -> Bool {
  defer {
   #if DEBUG
    log(index, terminator: "\n\n", with: "index")
   #endif
   publisher.objectWillChange.send()
  }
  if exists {
   if traits.isObservable { publisher.observe(self) }
   return true
  } else {
   // publisher.stopObserving(self)
   return false
  }
 }

 @discardableResult func update() -> Bool { updateIfExisting() }

 /// Useful when the dynamic content of a content structure is changed
 /// - returns: true if the content exists on the filesystem
 @discardableResult func updateMirror() -> Bool {
  updateIndex()
  return updateIfExisting()
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
     remove()
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
  log(
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
   #if os(macOS)
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
   #else
    try? url.resourceValues(
     forKeys: [
      .isDirectoryKey,
      .isHiddenKey,
      .isExecutableKey,
      .fileResourceTypeKey,
      .contentTypeKey,
      .localizedTypeDescriptionKey
     ]
    )
   #endif
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

 #if os(macOS)
  var tagNames: [String]? {
   self[resource: .tagNamesKey] as? [String]
  }
 #endif

 func updateResources() {
  guard let values = resourceValues else { return }
  resources[any: DirectoryKey()] = values.isDirectory as Any
  resources[any: HiddenKey()] = values.isHidden as Any
  resources[any: ExecutableKey()] = isExecutable as Any
  resources[any: URLFileResourceTypeKey()] = values.fileResourceType as Any
  resources[any: TypeIdentifierKey()] = values.contentType as Any
  resources[any: TypeDescriptionKey()] = values.localizedTypeDescription as Any
  #if os(macOS)
   resources[any: TagNamesKey()] = values.tagNames as Any
  #endif
 }

 func setResources() {
  updateResources()
  for keyDescription in usedResources {
   guard let value = resourceCache[keyDescription],
         let fileKey = urlResourceKey(for: keyDescription) else { continue }
   self[resource: fileKey] = value
  }
 }

 func displayResources() {
  log(
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
  case TagNamesKey.description:
   #if os(macOS)
    return .tagNamesKey
   #else
    return nil
   #endif
  default: return nil
  }
 }

 var attributes: Attributes {
  get { attributesCache.values.unsafelyUnwrapped }
  set {
   usedAttributes.formUnion(Set(newValue.values.keys))
   attributesCache.values = newValue
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
  updatePath()
 }

 func displayAttributes() {
  log(
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
  log(
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
 public static let types: Set<String> = [
  // MARK: Structural
  "Folder",
  "ForEach",
  "Group",
//  "Array",
  // MARK: Structured
  "Structure",
  "NominalStructure",
  // MARK: Modified Structures
  "CodableContentModifier",
  "BufferModifier"
 ]

 static var filterCount: Int { types.count }
}

// MARK: Properties
extension Reflection {
 var directory: URL {
  do {
   return parent == nil ?
    try publisher.contentURL() : parent.unsafelyUnwrapped.url
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
    #if DEBUG
     log("Created folder at \"\(directory.path)\"")
    #endif
   }
  } catch {
   onError?(.url(error))
   fatalError()
  }
 }

 @discardableResult func updatePath() -> String {
  var base = directory
  guard
   let name = attributes.name.wrapped ?? name?.wrapped else { return base.path }
  base.appendPathComponent(name)
  path = base.path
  return base.path
 }

 var _path: String {
  if let path { return path } else {
   return updatePath()
  }
 }

 var _url: URL? {
  guard let path else { return nil }
  return URL(fileURLWithPath: path)
 }

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
    #if DEBUG
     log("Created folder at \"\(directory.path)\"")
    #endif
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
  guard let _url else {
   return
  }
  try publisher.removeItem(at: _url)
 }

 func trash() throws {
  guard let _url else {
   return
  }
  var destination: NSURL?
  try publisher.trashItem(at: _url, resultingItemURL: &destination)
  if let destination { recoveryURL = destination as URL }
 }

 func remove() {
  do {
   if traits.removalMethod == .delete {
    try delete()
   } else {
    try trash()
   }
  } catch {
   onError?(.remove(error))
   fatalError(error.localizedDescription)
  }
 }

 func create() {
  guard let structure else { fatalError() }
  // guard mirror == nil else { return }
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

// MARK: Transactional
// Create a transaction closure for reflections
/// TODO: Observe paths that structured content depends on, if set to be
/// observable then cache, filter, and page values based on context
extension Reflection {
 var root: Reflection? {
  self.traits.contentType == .folder ? self : self.parent
 }

 func getURL(id: Any) -> URL? {
  let path = String(describing: id).readable
  guard let path = path.wrapped, path != "nil" else { return nil }
  self.name = path
  self.resolveTraits()
  return url
//  if let utType = traits.utType {
//   return directory.appendingPathComponent(path, conformingTo: utType)
//  } else {
//   return directory.appendingPathComponent(path)
//  }
 }

 func remove(id: Any) {
  guard let url = getURL(id: id) else { fatalError() }
  do {
   if traits.removalMethod == .delete {
    try publisher.removeItem(at: url)
   } else {
    var destination: NSURL?
    try publisher.trashItem(at: url, resultingItemURL: &destination)
    if let destination { recoveryURL = destination as URL }
   }
  } catch {
   onError?(.remove(error))
  }
 }

 func set(_ newValue: (some Any)?, id: Any) {
  if let newValue {
   guard let url = getURL(id: id) else { return }
   do {
    try structure.unsafelyUnwrapped.encode(any: newValue)?
     .write(to: url, options: .atomic)
   } catch {
    onError?(.set(error))
   }
  } else {
   remove(id: id)
  }
 }

 func getAll<Value>(as type: Value.Type) -> [Value] {
  guard let root, let utType = traits.utType,
        let contents = try? publisher.contentsOfDirectory(
         at: root.directory, includingPropertiesForKeys: [.contentTypeKey]
        )
  else { return .empty }
  return contents.compactMap { url in
   let `extension` = url.pathExtension
   if utType.preferredFilenameExtension == `extension` {
    let name = url.deletingPathExtension().lastPathComponent
    return get(id: name, as: Value.self)
   }
   return nil
  }
 }

 func get<A>(id: Any, as type: A.Type) -> A? {
  guard let url = getURL(id: id) else { return nil }
  do {
   return try structure.unsafelyUnwrapped
    .decode(any: Data(contentsOf: url), as: type)
  } catch {
   onError?(.get(error))
   return nil
  }
 }
}

extension Reflection {
 func getURL(id: Any, on structure: some EnclosedContent) -> URL? {
  let path = String(describing: id).readable
  guard let path = path.wrapped, path != "nil" else { return nil }
  guard let root else { fatalError() }
  if let utType = structure._traits.utType {
   return root.directory.appendingPathComponent(path, conformingTo: utType)
  } else {
   return root.directory.appendingPathComponent(path)
  }
 }

 func remove(id: Any, on structure: some EnclosedContent) {
  guard let url = getURL(id: id, on: structure) else { fatalError() }
  do {
   if structure._traits.removalMethod == .delete {
    try publisher.removeItem(at: url)
   } else {
    var destination: NSURL?
    try publisher.trashItem(at: url, resultingItemURL: &destination)
    if let destination { recoveryURL = destination as URL }
   }
  } catch {
   onError?(.remove(error))
  }
 }

 func set<A: EnclosedContent>(_ newValue: A.Value?, id: Any, on structure: A) {
  if let newValue {
   guard let url = getURL(id: id, on: structure) else { return }
   do {
    try structure.encode(newValue).write(to: url)
   } catch {
    onError?(.set(error))
   }
  } else {
   remove(id: id, on: structure)
  }
 }

 func getAll<A: EnclosedContent>(on structure: A) -> [A.Value] {
  guard let root, let utType = structure._traits.utType,
        let contents = try? publisher.contentsOfDirectory(
         at: root.directory, includingPropertiesForKeys: [.contentTypeKey]
        )
  else { return .empty }
  return contents.compactMap { url in
   let `extension` = url.pathExtension
   if utType.preferredFilenameExtension == `extension` {
    let name = url.deletingPathExtension().lastPathComponent
    return get(id: name, on: structure)
   }
   return nil
  }
 }

 func get<A: EnclosedContent>(id: Any, on structure: A) -> A.Value? {
  guard let url = getURL(id: id, on: structure) else { return nil }
  do {
   return try structure.decode(Data(contentsOf: url, options: .mappedIfSafe))
  } catch {
   onError?(.get(error))
   return nil
  }
 }
}
