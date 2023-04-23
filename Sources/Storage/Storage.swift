@_exported import Extensions
@_exported import Configuration
#if os(Linux)
 @_exported import OpenCombine
#else
 @_exported import Combine
#endif

public var config: Configuration = .defaultValue
@inline(__always) let log = config

public enum Error: Swift.Error {
 case url(Swift.Error),
      invalidTarget(String),
      invalidTransaction(Swift.Error),
      create(Swift.Error),
      existingFile(URL),
      set(Swift.Error),
      get(Swift.Error),
      remove(Swift.Error),
      setAttribute(FileAttributeKey),
      getAttribute(FileAttributeKey),
      setResource(URLResourceKey),
      getResource(URLResourceKey),
      encoding(Any.Type, reason: String? = nil),
      decoding(Any.Type, reason: String? = nil)
}

extension Error: LocalizedError {
 public var failureReason: String? {
  switch self {
  case let .url(error):
   return "url error: \(error.localizedDescription)"
  case let .invalidTransaction(error):
   return "transaction error: \(error.localizedDescription)"
  case let .invalidTarget(key): return "invalid target: \(key)"
  case let .existingFile(url): return "file exists at \"\(url.path)\""
  case let .setAttribute(key):
   return "attribute for key: \(key.rawValue), wasn't able to be set"
  case let .getAttribute(key):
   return "attribute for key: \(key.rawValue), doesn't exist"
  case let .setResource(key):
   return "resource for key: \(key.rawValue), wasn't able to be set"
  case let .getResource(key):
   return "resource for key: \(key.rawValue), doesn't exist"
  case let .set(error):
   return "set error: \(error.localizedDescription)"
  case let .get(error):
   return "get error: \(error.localizedDescription)"
  case let .remove(error):
   return "remove error: \(error.localizedDescription)"
  case let .encoding(type, reason):
   return "encoding error: \(type) couldn't be encoded" + (
    reason == nil ? .empty : ", \(reason!)"
   )
  case let .decoding(type, reason):
   return "decoding error: \(type) couldn't be decoded" + (
    reason == nil ? .empty : ", \(reason!)"
   )
  case let .create(error):
   return "creation error: \(error.localizedDescription)"
  }
 }

 public var localizedDescription: String {
  failureReason ?? "unknown"
 }
}
