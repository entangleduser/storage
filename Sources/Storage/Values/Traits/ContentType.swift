struct ContentType: OptionSet, @unchecked Sendable {
 let rawValue: UInt
 public init(rawValue: UInt) { self.rawValue = rawValue }

 static let file = Self(rawValue: 1 << 0)
 static let folder = Self(rawValue: 1 << 1)
 static let all = [file, folder]
}
