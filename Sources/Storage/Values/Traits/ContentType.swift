public struct ContentType: OptionSet, @unchecked Sendable {
 public let rawValue: UInt
 public init(rawValue: UInt) { self.rawValue = rawValue }

 public static let file = Self(rawValue: 1 << 0)
 public static let folder = Self(rawValue: 1 << 1)
 public static let any = [file, folder]
}
