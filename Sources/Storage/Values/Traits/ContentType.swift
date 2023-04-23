public struct ContentType: OptionSet, @unchecked Sendable {
 public let rawValue: UInt
 public init(rawValue: UInt) { self.rawValue = rawValue }

 public static let file = Self(rawValue: 1 << 0)
 public static let folder = Self(rawValue: 1 << 1)
 public static let any = [file, folder]
}

extension ContentType: CustomStringConvertible {
 public var description: String {
  switch self {
  case .file: return "file"
  case .folder: return "folder"
  case [.file, .folder]: return "any"
  default: fatalError()
  }
 }
}
