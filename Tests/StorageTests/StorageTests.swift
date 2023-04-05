@testable import Storage
import XCTest

@MainActor final class StorageTests: XCTestCase {
 func testContentCache() {
  measure { print(ContentManager.standard.static) }
 }

 func testStaticContent() {
  ContentApp.main()
 }
}

// MARK: - Codable structures and ContentPublisher
struct EmptyStructure: Codable, Infallible {
 static let defaultValue = Self()
 var info = "Default Info"
}

extension [String: String]: SelfCodable {
 public static func encode(_ value: Self) throws -> Data {
  try JSONEncoder().encode(value)
 }

 public static func decode(_ data: Data) throws -> Self {
  try JSONDecoder().decode(Self.self, from: data)
 }
}

@MainActor final class ContentManager: FileObserver, ContentPublisher {
 static let standard = ContentManager()
 static let searchPath: SearchPath = .cache
 @Public var `static`: Contents
 /// todo: pass ``NominalStructure`` to read and write structures that are
 /// static
}

// MARK: - Content Structure
struct Contents: PublicContent {
 @Alias var readme: String?
 @Alias var json: EmptyStructure?
 @Alias var json2: EmptyStructure?
 @Alias var json3: EmptyStructure?
 @Alias var json4: EmptyStructure?

 var content: some Content {
  /// - note: can rebuild on changes to some properties
  /// but this function must be accessed again to reflect the changes
  /// this is normally done when a state variable changes, but a binding is
  /// acceptable to allow the intrinsic structure to be modified after updating
  /// and notifying the publisher assigned to the reflection
  /// aliases update the structure but since it's ideal to separate isolated
  /// content structures from views, state variables don't udpate content on
  /// demand, but using another property wrapper for content is possible
  /// transactions work through aliases with
  /// `$alias.set(newValue, with: "name")`, `$alias.get("name")` _or_
  /// `$alias["name"] = newValue`, `$alias["name"]`
  Folder("Static") {
   /// - remark
   /// `StructuredContent` will write if a default value is provided
   /// or if it's written to by an `Alias`
   Nominal("README", default: "# Contents")
    .type(.markdown)
    .alias($readme)
   /// - note provides a default value with the `??` operator
   /// A test swift script that can execute a swift script using swift-sh
   (Nominal("test") ??
    "#!/usr/bin/swift sh\nlet str = \"Hello World!\"\nprint(str)")
    .type(.swiftSource)
    .permissions(.ownerReadWriteExecute)
   Group {
    JSON<EmptyStructure>("2").alias($json2)
    JSON<EmptyStructure>("3").alias($json3)
    JSON<EmptyStructure>("4").alias($json4)
   }
   .type(.json)
  }
  // MARK: - Transactional Interface
  Folder("Transactional") {
   // when the transaction is changed, so are the contents
   // it's optional but most times required to read the folder and
   // and create bindings to the relevant files in a single data
   // structure to encode and decode the alias that relate to the
   // transaction, therefore transactions must be written to the file
   // through an alias or `ContentStructure`
   /* ContentTransaction<UUIDTransaction<UUID>> { reciept in
     Folder(reciept.source) {
      JSON<EmptyStructure>("Sender").type(.json)
      Folder(reciept.target) {
       JSON<EmptyStructure>("Reciever").type(.json)
      }
     }
    } */
   JSON<EmptyStructure>().alias($json)
   JSON<EmptyStructure>().alias($json2)
  }
  .type(.json)
 }
}

import SwiftUI
// MARK: ContentApp - A test app for creating observable content
struct ContentApp: App {
 @ObservableContent var content: ContentManager
 var body: some Scene {
  WindowGroup("Contents") {
   ContentView().environmentObject(content)
    .frame(width: 275, height: 275)
  }
 }
}


struct ContentView: View {
 @EnvironmentObject var content: ContentManager
 var deletedReadMe: Bool { content.static.readme == nil }
 var deletedJSON: Bool { content.static.json?.info == nil }
 var deletedJSON2: Bool { content.static.json2?.info == nil }
 var deletedJSON3: Bool { content.static.json3?.info == nil }
 var deletedJSON4: Bool { content.static.json4?.info == nil }

 var body: some View {
  ScrollView {
   VStack {
    HStack {
     Text(content.static.readme ?? "Readme Missing")
      .font(.title2)
      .lineLimit(.max)
      .frame(maxHeight: .infinity)
      .multilineTextAlignment(.leading)
     Spacer()
     VStack {
      Spacer()
      Button(deletedReadMe ? "Restore" : "Delete") {
       if deletedReadMe {
        content.static.readme = "Restored Contents"
       } else {
        content.static.readme = nil
       }
       content.display()
      }
      .frame(width: 72, alignment: .trailing)
      .buttonStyle(.bordered)
     }
    }
    .padding(.top, 8.5)
    VStack {
     HStack {
      HStack {
       Text(1.description)
        .foregroundColor(.secondary)
       Spacer()
       Text(content.static.$json["1"]?.info ?? "JSON Missing")
      }
      Spacer()
      VStack {
       Spacer()
       Button(deletedJSON ? "Restore" : "Delete") {
        if deletedJSON {
         content.static.$json["1"] = .defaultValue
         content.static.$json["1"]?.info = "Restored JSON"
        } else {
         content.static.json = nil
        }
        content.display()
       }
       .frame(width: 72, alignment: .trailing)
       .buttonStyle(.bordered)
      }
     }
     Divider()
     HStack {
      HStack {
       Text(2.description)
        .foregroundColor(.secondary)
       Spacer()
       Text(content.static.$json2["2"]?.info ?? "JSON Missing")
      }
      Spacer()
      VStack {
       Spacer()
       Button(deletedJSON2 ? "Restore" : "Delete") {
        if deletedJSON2 {
         content.static.$json2["2"] = .defaultValue
         content.static.$json2["2"]?.info = "Restored JSON"
        } else {
         content.static.json2 = nil
        }
        content.display()
       }
       .frame(width: 72, alignment: .trailing)
       .buttonStyle(.bordered)
      }
     }
     Divider()
     HStack {
      HStack {
       Text(3.description)
        .foregroundColor(.secondary)
       Spacer()
       Text(content.static.json3?.info ?? "JSON Missing")
      }
      Spacer()
      VStack {
       Spacer()
       Button(deletedJSON3 ? "Restore" : "Delete") {
        if deletedJSON3 {
         content.static.json3 = .defaultValue
         content.static.json3?.info = "Restored JSON"
        } else {
         content.static.json3 = nil
        }
        content.display()
       }
       .frame(width: 72, alignment: .trailing)
       .buttonStyle(.bordered)
      }
     }
     Divider()
     HStack {
      HStack {
       Text(4.description)
        .foregroundColor(.secondary)
       Spacer()
       Text(content.static.json4?.info ?? "JSON Missing")
      }
      Spacer()
      VStack {
       Spacer()
       Button(deletedJSON4 ? "Restore" : "Delete") {
        if deletedJSON4 {
         content.static.json4 = .defaultValue
         content.static.json4?.info = "Restored JSON"
        } else {
         content.static.json4 = nil
        }
        content.display()
       }
       .frame(width: 72, alignment: .trailing)
       .buttonStyle(.bordered)
      }
     }
    }
    .padding()
    .background(Color.white.opacity(0.1))
    .cornerRadius(8.5)
    .padding(.top, 8.5)
   }
   .padding(.horizontal)
  }
  .onAppear(perform: content.display)
 }
}

