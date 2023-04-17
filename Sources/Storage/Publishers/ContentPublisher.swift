import Foundation
import Extensions
@_exported import struct Reflection.PropertyInfo

// MARK: Types
public enum ContentSearchPath: @unchecked Sendable {
 case
  cache,
  application,
  user,
  desktop,
  music,
  downloads,
  documents,
  pictures,
  movies,
  trash,
  custom(String)
}

public struct ContentDomainMask: OptionSet, @unchecked Sendable {
 public let rawValue: UInt

 public static let install = Self(rawValue: 1 << 0)
 public static let system = Self(rawValue: 1 << 1)
 public static let network = Self(rawValue: 1 << 2)
 public static let user = Self(rawValue: 1 << 3)
 public static let all: Self = [.install, .system, .network, .user]

 public init(rawValue: UInt) { self.rawValue = rawValue }
}

// MARK: Protocols
public protocol StaticPublisher: ObservableObject, Identifiable
where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
 static var standard: Self { get }
}

public protocol ContentPublisher: ContentObserver, StaticPublisher {
 typealias SearchPath = ContentSearchPath
 typealias DomainMask = ContentDomainMask
 static var searchPath: SearchPath { get }
 static var domainMask: DomainMask { get }
 static var standard: Self { get }
}

extension ContentPublisher {
 @_disfavoredOverload
 public static var standard: Self { Self() }
 public static var domainMask: DomainMask { .all }
 var searchPath: SearchPathDirectory? {
  switch Self.searchPath {
  case .cache: return .cachesDirectory
  case .application: return .applicationSupportDirectory
  case .desktop: return .desktopDirectory
  case .music: return .musicDirectory
  case .downloads: return .downloadsDirectory
  case .documents: return .documentDirectory
  case .pictures: return .picturesDirectory
  case .movies: return .moviesDirectory
  case .trash: return .trashDirectory
  default: return nil
  }
 }

 var domainMask: SearchPathDomainMask? {
  switch Self.domainMask {
  case .all: return .allDomainsMask
  case .install: return .localDomainMask
  case .system: return .systemDomainMask
  case .network: return .networkDomainMask
  case .user: return .userDomainMask
  default: return nil
  }
 }

 func id(for searchPath: SearchPathDirectory) -> String? {
  switch searchPath {
  case .applicationSupportDirectory:
   return config.appName
  default: break
  }
  return config.bundleName
 }
}

extension ContentPublisher {
 func contentURL() throws -> URL {
  guard let searchPath, let domainMask, let id = id(for: searchPath) else {
   fatalError("No id could be determined for \(Self.self)")
  }
  return try url(
   for: searchPath,
   in: domainMask, appropriateFor: nil,
   create: true
  )
  .appendingPathComponent(id, isDirectory: true)
 }

 func contentPath() throws -> String { try contentURL().path }
 func createContentURL() throws -> URL {
  var isDirectory: ObjCBool = false
  let url = try contentURL()
  if fileExists(atPath: url.path, isDirectory: &isDirectory) {
   if isDirectory.boolValue {
    return url
   } else {
    fatalError()
   }
  } else {
   try createDirectory(atPath: url.path, withIntermediateDirectories: true)
   return url
  }
 }

 var url: URL { try! createContentURL() }
}

public protocol ContentCache: AnyObject {
 var ignore: Bool { get set }
 var id: ObjectIdentifier { get }
 var keyType: Any.Type! { get set }
 var key: AnyHashable? { get set }
 var cache: [AnyHashable: [AnyHashable: ContentMirror]] { get set }
 var reflections: [[ReflectionIndex: Reflection]] { get set }
 var properties: [[UUID: (PropertyInfo, ReflectionIndex)]] { get set }
 var filters: [BloomFilter<String>] { get set }
 var offset: Int { get set }
 var values: [[SomeContent]] { get set }
 var elements: [[ReflectionIndex]] { get set }
}

extension ContentCache {
 var mirrors: [ContentMirror] { cache.values.map(\.values).flatMap { $0 } }
 var mirrorCount: Int { mirrors.count }
 var allValues: [SomeContent] { values.flatMap { $0 } }
 var allReflections: [Reflection] { allValues.compactMap(\._reflection) }
 var reflectionCount: Int { allReflections.count }
 var uniqueReflectionCount: Int { allReflections.unique().count }

 public func display() {
  log(
   "\(Self.self, color: .yellow, style: .bold) ↘︎",
   " Mirrors: " + mirrorCount.description,
   " Elements: " + elements.count.description,
   " Reflections: " + reflectionCount.description +
    ", Unique: " + uniqueReflectionCount.description,
   " LastOffset: " + offset.description,
   separator: .newline,
   terminator: "\n\n"
  )
 }
}

extension ContentCache where Self: ContentPublisher {
 public func display() {
  log(
   "\(Self.self, color: .yellow, style: .bold) ↘︎",
   " Path: " + (try! contentPath()),
   " Mirrors: " + mirrorCount.description,
   " Elements: " + elements.flatMap { $0 }.count.description,
   " Reflections: " + reflectionCount.description +
    ", Unique: " + uniqueReflectionCount.description,
   " LastOffset: " + offset.description,
   separator: .newline,
   terminator: "\n\n"
  )
 }

 /// The default reflection function for a custom content type
 @inline(__always) func cache(_ contents: [SomeContent]) -> SomeContent {
  ignore = true

  let keyType = self.keyType ?? type(of: contents.first!)
  if let mirror = self[cached: key, for: keyType] { return mirror.first }

  let mirror = ContentMirror(
   publisher: self,
   key: key,
   keyType: keyType,
   reflections: &reflections,
   properties: &properties,
   filters: &filters,
   values: &values,
   elements: &elements,
   contents,
   offset: &offset
  )

  self[cached: key, for: keyType] = mirror

  return self[cached: key, for: keyType]!.values[mirror.index].first!
 }

 @inline(__always) func reflect<A: Content>(
  with key: AnyHashable?, for keyType: Any.Type? = nil,
  @Storage.Contents content: @escaping () -> A
 ) -> Reflection {
  ignore = true

  let keyType = keyType ?? A.self
  if let mirror = self[cached: key, for: keyType] {
   return mirror.first._reflection.unsafelyUnwrapped
  }

  let mirror = ContentMirror(
   publisher: self,
   key: key,
   keyType: keyType,
   reflections: &reflections,
   properties: &properties,
   filters: &filters,
   values: &values,
   elements: &elements,
   ignoreContent { content() as! [SomeContent] },
   offset: &offset
  )

  self[cached: key, for: keyType] = mirror

  return self[cached: key, for: keyType]!.first._reflection.unsafelyUnwrapped
 }

 @usableFromInline
 subscript(cache key: AnyHashable? = nil) -> [AnyHashable: ContentMirror]? {
  get { cache[key ?? AnyHashable(id)] }
  set {
   guard let newValue else { return }
   cache[key ?? AnyHashable(id), default: .empty] = newValue
  }
 }

 @usableFromInline subscript(
  cached key: AnyHashable? = nil, for type: Any.Type
 ) -> ContentMirror? {
  get { self[cache: key ?? id.erasedToAny]?[ObjectIdentifier(type)] }
  set {
   guard let newValue else { return }
   cache[
    key ?? id.erasedToAny, default: .empty
   ][ObjectIdentifier(type)] = newValue
  }
 }

 @usableFromInline subscript<A: Content>(
  content type: A.Type, for key: AnyHashable? = nil
 ) -> A? {
  get { self[cache: key ?? id.erasedToAny]?[ObjectIdentifier(type)]?.first as? A }
  set {
   guard let newValue else { return }
   self[cache: key ?? id.erasedToAny]?[ObjectIdentifier(type)]?.first = newValue
  }
 }
}

// MARK: Objects
/// A base class that observes changes to content
open class ContentObserver: FileManager {
 override public required init() { super.init() }
 public var ignore = true
 public var id: ObjectIdentifier { ObjectIdentifier(self) }
 public var cache: [AnyHashable: [AnyHashable: ContentMirror]] = .empty
 public var keyType: Any.Type!
 public var key: AnyHashable?
 public var reflections: [[ReflectionIndex: Reflection]] = .empty
 public var properties: [[UUID: (PropertyInfo, ReflectionIndex)]] = .empty
 public var filters: [Extensions.BloomFilter<String>] = .empty
 public var offset: Int = .zero
 public var values: [[SomeContent]] = .empty
 public var elements: [[ReflectionIndex]] = .empty

 var paths = Set<String>()
 var sources = [String: DispatchSourceFileSystemObject]()
 private let dispatch = DispatchSource.self
 func observe(_ reflection: Reflection) {
  let path = reflection.directory.path

  if paths.contains(path) {
   if let source = sources[path] {
    close(source.handle)
    source.cancel()
    sources[path] = nil
   }
  } else {
   paths.insert(path)
  }

  if reflection.exists {
   let source = dispatch.makeFileSystemObjectSource(
    fileDescriptor: open(path, O_EVTONLY),
    /// - remark `all`
    /// works in most circumstances where `delete` doesn't recognize changes
    eventMask: .all,
    queue: .main
   )

   sources[path] = source
   source.setEventHandler(handler: reflection.observationHandler)
   source.resume()
  }
 }

 func stopObserving(_ reflection: Reflection) {
  let path = reflection.directory.path
  guard paths.contains(path),
        let source = sources[path] else { fatalError() }
  paths.remove(path)

  close(source.handle)
  source.cancel()
  sources[path] = nil
 }

 deinit {
  for (path, source) in sources {
   close(source.handle)
   source.cancel()
   sources[path] = nil
  }
 }
}

public typealias ContentCacheable = ContentPublisher & ContentCache
public typealias AnyContentPublisher = any ContentCacheable
public typealias ObservableContentPublisher = ContentCacheable & ContentObserver
public typealias ObservableDefaults = ObservableContentPublisher & DefaultsPublisher
// MARK: Defaults
/// The default publisher, if there's an app delegate it would probably
/// be beneficial to subclass this in order to allow view updates from
/// content and defaults from anywhere the observed object is placed
open class DefaultPublisher: ObservableDefaults {
 // TODO: Add search path override to traits
 public static var searchPath: SearchPath = .cache
 //public static var standard: Self { Self() }
}
