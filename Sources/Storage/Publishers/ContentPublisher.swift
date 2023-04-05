import Foundation
@testable import Extensions
@testable import Composite
import Chalk
protocol StaticPublisher: ObservableObject
where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
 static var standard: Self { get }
}
protocol ContentPublisher: FileObserver, Identifiable, StaticPublisher {
 typealias SearchPath = ContentSearchPath
 typealias DomainMask = ContentDomainMask
 static var searchPath: SearchPath { get }
 static var domainMask: DomainMask { get }
 static var standard: Self { get }
}

extension ContentPublisher {
 func mirror(_ contents: [AnyContent]) -> [AnyContent] {
  defer { _ignore = false }
  _ignore = true

  let mirror = ContentMirror(contents)

  self[mirror: mirror.keyType] = mirror
  mirror.reset()

  return [mirror.first]
 }

 subscript(mirror type: (some Content).Type) -> ContentMirror? {
  get { _mirrors[id]?[ObjectIdentifier(type)] }
  set { _mirrors[id, default: .empty][ObjectIdentifier(type)] = newValue }
 }

 subscript(mirror type: Any.Type) -> ContentMirror? {
  get { _mirrors[id]?[ObjectIdentifier(type)] }
  set { _mirrors[id, default: .empty][ObjectIdentifier(type)] = newValue }
 }

 @inlinable subscript<A: Content>(content type: A.Type) -> A? {
  get { self[mirror: type]?.first as? A }
  set { self[mirror: type]?.first = newValue }
 }

 var mirrorCount: Int {
  _mirrors[id, default: .empty].count
 }

 var reflectionCount: Int {
  _mirrors[id, default: .empty].values
   .reduce(into: 0) { partialResult, next in
    partialResult += _values[next.index]
     .reduce(into: 0) { partialResult, next in
      guard next._reflection != nil else { return }
      partialResult += 1
     }
   }
 }

 var storage: [ObjectIdentifier: ContentMirror] {
  _mirrors[id, default: .empty]
 }

 var mirrors: [ContentMirror] { storage.values.map { $0 } }

 func display() {
  print(
   "\(Self.self, color: .yellow, style: .bold) ↘︎",
   " Path: " + (try! contentPath()),
   " Mirrors: " + mirrorCount.description,
   " Elements: " + _elements.count.description,
   " Reflections: " + reflectionCount.description,
   " LastOffset: " + _lastOffset.description,
   separator: .newline,
   terminator: "\n\n"
  )
 }

 var url: URL { try! createContentURL() }

 static var domainMask: DomainMask { .all }
 @inlinable
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
   return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ??
    Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String
  default: break
  }
  return Bundle.main.bundleIdentifier ?? {
   let info = ProcessInfo.processInfo
   return info.fullUserName
    .split(separator: .space).map { $0.lowercased() }
    .joined(separator: .period)
    .appending(.period + info.processName)
  }()
 }

 var currentPath: String { currentDirectoryPath }
 var userPath: String { homeDirectoryForCurrentUser.path }
}

/// A base class that observes changes to a file
// TODO: track the location of values that have no deterministic path
class FileObserver: FileManager {
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

enum ContentSearchPath: @unchecked Sendable {
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

struct ContentDomainMask: OptionSet, @unchecked Sendable {
 let rawValue: UInt

 static let install = Self(rawValue: 1 << 0)
 static let system = Self(rawValue: 1 << 1)
 static let network = Self(rawValue: 1 << 2)
 static let user = Self(rawValue: 1 << 3)
 static let all: Self = [.install, .system, .network, .user]

 public init(rawValue: UInt) { self.rawValue = rawValue }
}

// MARK: Defaults
final class DefaultPublisher: FileObserver, ContentPublisher {
 static let standard = DefaultPublisher()
 static let searchPath: SearchPath = .cache
}
