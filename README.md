# Storage ⏏︎
 A language inspired by the principles of SwiftUI that allows reading and writing encoded folder and content structures
 
 The aim of storage is to create a repeatable and observable interface between the user and the framework through the use of transactions, property wrappers, and content decoders
 
 This is partially implemented and should be extended to every possible use case which is transparent reads and writes, querying, and creating content outside of the file manager used to publish content
 
## Frameworks ⏎
### Core
 Provides the protocol for default values and encoding and decoding values with a static encoder and decoder
 
 As well as an index value, that allows the necessary recursion for indexing a recursive sequences of elements

### Composite
 Extends the values to store keyed values and content specific traits that are reflected and inherited by variadic and recursive content

### Reflection
 Allows setting and updating property wrappers on content (from the Tokamak framework)

## Conventions ⏎
 There two primary conventions used in this framework, `Content` and `Structure`
 A structure is content that contains a file or value that can be encoded or decoded using an alias property wrapper
 
### `Alias`  
 A property wrapper used to encode and decode a value with by calling a `alias` on the relevant structure
 
 `Content` is the base protocol for all values that are allowed within the framework but dynamic content allows reflection for folders and other content types that create the structure for a content publisher

### `ContentPublisher`
 An observable object that manages the default location and contents of an app
 
## Testing ⇥
 Run test target `StorageTests` from the package
 This contains a sample app and benchmark on the caching of contents within a publisher
 
## Using `Storage` ⇢

### Creating a content publisher
``` swift
@testable import Storage /// - Note `@testable` required until the evaluation is over
/// A main actor that conforms to `FileObserver` and `ContentPublisher`
@MainActor final class ContentManager: FileObserver, ContentPublisher {
/// A standard static property must be declared to prevent more than one copy
 static let standard = ContentManager()
 
 /// The search path or stored location for content
 static let searchPath: SearchPath = .cache
 
 /// A wrapped property used to load content that conforms to `PublicContent`
 @Public var `static`: Contents
}
```

### Creating the content for a publisher
``` swift
/// A struct that conforms to `PublicContent` so it can be wrapped using the `@Public` 
property wrapper on a content publisher
struct Contents: PublicContent {
 /// A wrapped structure conforming to `Codable`, `AutoCodable`, or `SelfCodable`
 @Alias var script: String?
 @Alias var readme: String?
 @Alias var json: EmptyStructure?
 @Alias var json2: EmptyStructure?
 @Alias var json3: EmptyStructure?

 var content: some Content {
  Folder("Cache") {
   /// A test swift script that can execute a swift script using `swift-sh`
   (Nominal("test") ??
    // the default value can be indicated using the operator `??`
    // or else the value won't be created automatically
    "#!/usr/bin/swift sh\nlet str = \"Hello World!\"\nprint(str)")
    // the type / extension for a structure
     .type(.swiftSource)
     .permissions(.ownerReadWriteExecute)
     .alias($script)

   Nominal("README", default: "# Contents")
    .type(.markdown)
    // creates a binding to the structure
    .alias($readme)
   Group {
    JSON<EmptyStructure>("1").alias($json)
    JSON<EmptyStructure>("2").alias($json2)
    JSON<EmptyStructure>("3").alias($json3)
   }
   .type(.json)
  }
 }
}

/// A structure conforming to `Codable` and `Infallible` to provide a
/// default value when encoding
struct EmptyStructure: Codable, Infallible {
 static let defaultValue = Self()
 var info = "Default Info"
}
```

### Accessing the content within a ``View``
``` swift
import SwiftUI
struct ContentView: View {
 @ObservableContent var content: ContentManager = .standard
 var body: some View {
  ScrollView {
   VStack {
    Text(content.static.readme ?? "Readme Missing")
     .font(.title2)
     .lineLimit(.max)
     .frame(maxHeight: .infinity)
     .multilineTextAlignment(.leading)
    HStack {
     Spacer()
     Button(content.static.readme == nil ? "Restore" : "Delete") {
      if content.static.readme == nil {
       // sets the contents of `readme`
       content.static.readme = "Restored Contents"
      } else {
       // deletes the file
       content.static.readme = nil
      }
     }
     .frame(width: 72, alignment: .trailing)
     .buttonStyle(.bordered)
    }
   }
   Divider()
   VStack {
    Text(content.static.json?.info ?? "JSON Missing")
     .font(.title2)
     .lineLimit(.max)
     .frame(maxHeight: .infinity)
     .multilineTextAlignment(.leading)
    HStack {
     Spacer()
     Button(content.static.json == nil ? "Restore" : "Delete") {
      if content.static.json == nil {
       // creates the file indicated by the alias
       content.static.json = .defaultValue
       content.static.json?.info = "Restored Info"
       // or subscript for unnamed structures with an alias
       // the complete framework should provide a solution for complete
       // sending and recieving of transactions but can get and set a value
       // by name at the present
       content.static.$json["1"] = .defaultValue
       content.static.$json["1"]?.info = "Restored Info"
       // `content.static.$binding` can be connected to a view but will be
       // optional because the contents of a filesystem are unpredictable
      } else {
       // deletes the file for the property `json`
       content.static.json = nil
      }
     }
     .frame(width: 72, alignment: .trailing)
     .buttonStyle(.bordered)
    }
   }
  }
 }
}
```

## Contributing ✓
 All feedback, criticism, improvements through pull request, and reported issues are helpful but the repository is mostly for evaluation purposes and those who want to understand recursive data language structures in swift
 
## Credits
- [Tokamak](https://github.com/TokamakUI/Tokamak) for struct metadata and sharing some details of the SwiftUI implementation
- All open source code, including swift, the community and the SwiftUI library

## Limitations
- macOS only but can easily be extended to go cross platform because of the compatibility of the data structures of used
- Transactions and querying aren’t _yet_ supported through inline functions
