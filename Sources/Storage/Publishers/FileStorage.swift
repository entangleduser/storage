// public extension FileStorage {
// func id(for searchPath: SearchPathDirectory) -> String {
//  switch searchPath {
//   case .applicationSupportDirectory:
//    return
//     Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ??
//     Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String ??
//     ProcessInfo.processInfo.className
//   default: return Bundle.main.bundleIdentifier!
//  }
// }
//
//// func keys<Key: Transactional>(
////  for searchPath: SearchPathDirectory = Self.defaultSearchPath
//// ) throws -> [Key] {
////  let url = try url(for: searchPath)
//// }
// func ids(
//  for searchPath: SearchPathDirectory = Self.defaultSearchPath, with path: String
// ) throws -> [URL] {
//  let url = try url(for: searchPath).appendingPathComponent(path)
//  return try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
// }
// }
//
// public protocol StructuredFileStorage: FileStorage {
// func setTargetData<Key: Transactional>(_ value: Data?, for key: Key) throws
//
// func getTargetData<Key: Transactional>(for key: Key) throws -> Data?
//
// func removeTargetData<Key: Transactional>(for key: Key) throws
// }
//
// public extension FileStorage {
// /// Creates a folder if it doesn't exist, throws an error if it's a file
// @inline(__always)
// @discardableResult
// func folder(at url: URL) throws -> URL {
//  var isDirectory: ObjCBool = false
//  if fileExists(atPath: url.path, isDirectory: &isDirectory) {
//   if isDirectory.boolValue { return url }
//   else { throw Error.existingFile(url) }
//  } else {
//   try createDirectory(at: url, withIntermediateDirectories: true)
//  }
//  return url
// }
//
// func file(at url: URL) throws -> URL {
//  var isDirectory: ObjCBool = false
//  let base = url.deletingLastPathComponent()
//  if fileExists(atPath: base.path, isDirectory: &isDirectory) {
//   if isDirectory.boolValue {
//    try removeItem(at: base)
//    try createDirectory(at: base, withIntermediateDirectories: true)
//   } else {
//    try createDirectory(at: base, withIntermediateDirectories: true)
//   }
//  }
//  return url
// }
//
// @inline(__always)
// func url(
//  for searchPath: SearchPathDirectory = Self.defaultSearchPath,
//  appropriateFor: URL? = nil, create: Bool = false
// ) throws -> URL {
//  do {
//   let cachesURL = try url(
//    for: searchPath,
//    in: .userDomainMask, appropriateFor: appropriateFor, create: create
//   )
//   return try self.folder(at: cachesURL.appendingPathComponent(self.id(for: searchPath)))
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.urlError(error)
//  }
// }
//
// func getSourceURL(for key: some Transactional) throws -> URL? {
//  do { return try self.url().appendingPathComponent("\(key)") }
//  catch {
//   debugPrint(error.localizedDescription)
//   throw Error.urlError(error)
//  }
// }
//
// func setData(_ value: Data?, for key: some Transactional) throws {
//  do {
//   guard let url = try getSourceURL(for: key) else { return }
//   if let value { try value.write(to: url, options: .noFileProtection) }
//   else { try self.removeData(for: key) }
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
//
// func getData(for key: some Transactional) throws -> Data? {
//  do {
//   guard let url = try getSourceURL(for: key) else { return nil }
//   return try Data(contentsOf: url, options: .uncached)
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
//
// func removeData(for key: some Transactional) throws {
//  do {
//   guard let url = try getSourceURL(for: key) else { return }
//   try removeItem(at: url)
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
//
// // MARK: Targets
// func getTargetURL<Key: Transactional>(for key: Key) throws -> URL?
// where Key.Target: Transactional {
//  guard var paths = key.paths else {
//   throw Error.invalidTarget("\(key)")
//  }
//  do {
//   var url = try self.url()
//   let last = paths.removeLast()
//   url = url.appendingPathComponent(paths.joined(separator: "/"))
//   try createDirectory(at: url, withIntermediateDirectories: true)
//   url.appendPathComponent(last, isDirectory: false)
//   return url
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.urlError(error)
//  }
// }
//
// /// Invalidate or check data that has the same target but different source
// /// This can be any string that indicates a date, number, file, hash, or another source id
// func hasTarget(_ key: some Transactional) throws -> Bool {
//  try self.getTargetURL(for: key) != nil
// }
//
// func setTargetData(_ value: Data?, for key: some Transactional) throws {
//  do {
//   guard let url = try getTargetURL(for: key) else { return }
//   if let value { try value.write(to: url, options: .noFileProtection) }
//   else { try self.removeTargetData(for: key) }
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
//
// func getTargetData(for key: some Transactional) throws -> Data? {
//  do {
//   guard let url = try getTargetURL(for: key) else { return nil }
//   return try Data(contentsOf: url, options: .uncached)
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
//
// func removeTargetData(for key: some Transactional) throws {
//  do {
//   guard let url = try getTargetURL(for: key) else { return }
//   try removeItem(at: url)
//  } catch {
//   debugPrint(error.localizedDescription)
//   throw Error.invalidTransaction(error)
//  }
// }
// }
//
// open class UserFileStorage: FileManager, FileStorage, Storage, StructuredFileStorage {
// public static let standard = UserFileStorage()
// }
//
// public extension FileStorage where Self == UserFileStorage {
// static var standard: Self { .standard }
// }
//
// public extension StructuredFileStorage where Self == UserFileStorage {
// static var standard: Self { .standard }
// }
//
// #if canImport(AppKit)
// public extension UserFileStorage {
//  static var defaultSearchPath: FileManager.SearchPathDirectory {
//   .applicationSupportDirectory
//  }
// }
// #endif
//
// public protocol TransactionalProperty {
// associatedtype Key: Transactional
// var key: Key? { get }
// }
//
///// A cache property used to indicate a single value, structure, or location
// @propertyWrapper
// public struct FileStorageProperty<Value: AutoCodable, Key>: TransactionalProperty where
// Key: Transactional,
// Key.Source: Infallible {
// let wrapper: Self.Optional
// public var key: Key? { self.wrapper.key }
// var store: FileStorage { self.wrapper.store }
//
// public var wrappedValue: Value {
//  get { self.wrapper.wrappedValue! }
//  nonmutating set { wrapper.wrappedValue = newValue }
// }
//
// public func remove() throws { try self.wrapper.remove() }
//
// public init(wrappedValue: Value, _ key: Key, store: FileStorage? = nil) {
//  self.wrapper = Self.Optional(wrappedValue: wrappedValue, key, store: store)
// }
// }
//
// extension FileStorageProperty {
// @propertyWrapper
// public struct Optional {
//  // The prefix for storing files in a separate folder
//  public var key: Key?
//  public var store: FileStorage
//
//  public var wrappedValue: Value? {
//   get {
//    do {
//     guard let key else { return nil }
//     guard let data = try store.getData(for: key) else { return nil }
//     return try Value(data)
//    } catch {
//     debugPrint(error)
//     return nil
//    }
//   }
//   nonmutating set { self.set(newValue) }
//  }
//
//  @inline(__always) func set(_ newValue: Value?) {
//   guard let key else { return }
//   do { try self.store.setData(newValue.data, for: key) }
//   catch { fatalError(error.localizedDescription) }
//  }
//
//  /// - Note: Throws to validate the removal
//  public func remove() throws {
//   guard let key else { return }
//   try self.store.removeData(for: key)
//  }
//
//  public init(wrappedValue: Value? = nil, _ key: Key? = nil, store: FileStorage? = nil) {
//   if let store { self.store = store }
//   else { self.store = .standard }
//   self.key = key
//   if let wrappedValue { self.set(wrappedValue) }
//  }
// }
// }
//
// @propertyWrapper
// public struct OptionalFileStructure<Value: AutoCodable, Key>:
// TransactionalProperty where
// Key: Transactional & Infallible,
// Key.Target: Transactional {
// // The prefix for storing files in a separate folder
// public var key: Key?
// public var store: StructuredFileStorage
//
// public var wrappedValue: Value? {
//  get {
//   do {
//    guard let key else { return nil }
//    guard let data = try store.getTargetData(for: key) else { return nil }
//    return try Value(data)
//   } catch {
//    debugPrint(error)
//    return nil
//   }
//  }
//  nonmutating set { set(newValue) }
// }
//
// @inline(__always) func set(_ newValue: Value?) {
//  guard let key else { return }
//  do { try self.store.setTargetData(newValue.data, for: key) }
//  catch { fatalError(error.message) }
// }
//
// /// - Note: Throws to validate the removal
// public func remove() throws {
//  guard let key else { return }
//  try self.store.removeTargetData(for: key)
// }
//
// public init(
//  wrappedValue: Value? = nil, _ key: Key? = nil, store: StructuredFileStorage? = nil
// ) {
//  if let store { self.store = store }
//  else { self.store = .standard }
//  self.key = key
//  if let wrappedValue { self.set(wrappedValue) }
// }
// }
//
///// A cache property used to indicate a structure of potentially branching properties
// @propertyWrapper
// public struct FileStructure<Value: AutoCodable, Key>:
// TransactionalProperty where
// Key: Transactional & Infallible,
// Key.Target: Transactional {
// // MARK: Non Optional
// let wrapper: OptionalFileStructure<Value, Key>
// public var key: Key? { self.wrapper.key }
// var store: StructuredFileStorage { self.wrapper.store }
//
// public var wrappedValue: Value {
//  get { self.wrapper.wrappedValue! }
//  nonmutating set { wrapper.wrappedValue = newValue }
// }
//
// public func remove() throws { try self.wrapper.remove() }
//
// public init(wrappedValue: Value, _ key: Key, store: StructuredFileStorage? = nil) {
//  self.wrapper = .init(wrappedValue: wrappedValue, key, store: store)
// }
// }
//
// public extension FileStructure
// where Value: Stored & Infallible, Key == Value.ID {
// init(wrappedValue: Value = .defaultValue, store: StructuredFileStorage? = nil) {
//  self.init(
//   wrappedValue: wrappedValue, wrappedValue.id,
//   store: store
//  )
// }
// }
