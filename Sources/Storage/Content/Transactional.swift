import Transactions
import Composite
import Extensions
public protocol TransactionalContent: DynamicContent {
 associatedtype Elements: RandomAccessCollection
 var elements: Elements { get set }
}

// extension ForEach: TransactionalContent {}

/// A keypath based property, that updates the structured content
/// based on changes emmited by a publisher
@propertyWrapper public struct SubscribedProperty
<Publisher, Subject, Structure: StructuredContent>: DynamicProperty
 where Publisher: ContentPublisher & ContentCache,
 Subject:
 MutableCollection & RangeReplaceableCollection & RandomAccessCollection,
 Subject.Element: Hashable {
 public typealias Element = Subject.Element
 public init(
  subjectPath: ReferenceWritableKeyPath<Publisher, Subject>,
  keyPath: KeyPath<Element, String>
 ) {
  self.subjectPath = subjectPath
  self.keyPath = keyPath
 }

 public let id: UUID = .defaultValue
 public let subjectPath: ReferenceWritableKeyPath<Publisher, Subject>
 public let keyPath: KeyPath<Element, String>
 var keyTransaction: UUIDTransaction<String> {
  UUIDTransaction(from: id, to: elementName + contentName)
 }

 @inlinable public var publisher: Publisher { .standard }
 @inlinable public var subject: Subject {
  get { publisher[keyPath: subjectPath] }
  nonmutating set { publisher[keyPath: subjectPath] = newValue }
 }

 /// The key folder and structure that fits the expected content
 /// constructed through search parameters
 /// This is done through by subscripting an element and identifying by
 /// the specified key path or identifier by default
 @inlinable public var wrappedValue: [Element: Structure] {
  get {
   [Element: Structure](
    uniqueKeysWithValues: subject.map { key in (key, self[content: key]) }
   )
  }
  nonmutating set {
   self.update(newValue.keys)
   for key in newValue.keys {
    guard let newValue = newValue[key] else { fatalError() }
    self[content: key] = newValue
   }
  }
 }

 @inlinable public subscript(_ element: Element) -> Structure {
  get {
   append(element)
   return self[content: element]
  }
  nonmutating set {
   append(element)
   self[content: element] = newValue
  }
 }

 @inlinable public subscript(content element: Element) -> Structure {
  get {
   folder(for: element)?
    ._reflection!.index
    .first(where: { $0 is Structure }) as? Structure ??
    .defaultValue
  }
  nonmutating set {
   folder(for: element)?
    ._reflection!.index
    .compactMap { value in
     if var projectedValue = value as? Structure {
      projectedValue = newValue
      value = projectedValue
     }
    }
  }
 }

 public var projectedValue: Self { self }
 public func update() { publisher.objectWillChange.send() }
}

public extension SubscribedProperty {
 var contentName: String { "\(Structure.self)" }
 var elementName: String { "\(Element.self)" }
}

public extension SubscribedProperty {
 var reflection: Reflection {
  get {
   publisher.reflect(with: keyTransaction, for: Structure.self) {
    Folder(elementName) {
     ForEach(subject, id: keyPath) {
      Folder($0[keyPath: keyPath]) { Structure.defaultValue }
     }
    }
    /// - Note: Keys support finding and storing unique values with
    /// the current publisher
    .traits(\.key, self.keyTransaction)
   }
  }
  set {
   publisher[cached: keyTransaction, for: Structure.self]
    .unsafelyUnwrapped
    .first._reflection = newValue
  }
 }

 var contents: ForEach<Subject> {
  get {
   reflection.index
    .first(where: { $0 is ForEach<Subject> }) as! ForEach<Subject>
  }
  nonmutating set {
   reflection.index[{ $0 is ForEach<Subject> }] = newValue
  }
 }

 func updateContents() {
  contents = ForEach(subject, id: keyPath) {
   Folder($0[keyPath: keyPath]) { Structure.defaultValue }
  }
  reflection.updateIndex()
 }

 var folders: [any IdentifiableContent] {
  contents._reflection.unsafelyUnwrapped
   .index.compactMap { $0 as? any IdentifiableContent }
 }

 func folder(for element: Element) -> (any IdentifiableContent)? {
  folders.first(
   where: {
    if $0.id.description == element[keyPath: keyPath] {
     return true
    }
    return false
   }
  )
 }

 func append(_ element: Element) {
  let newValue = subject.appendingUnique(element)
  if !newValue.elementsEqual(subject) {
   subject = newValue
   updateContents()
  }
 }

 /// Recalculates the `ForEach` to reflect new elements
 func update(_ newValue: some Collection<Element>) {
  let newValue = subject.appendingUnique(newValue.first!)
  if !newValue.elementsEqual(subject) {
   subject.append(contentsOf: newValue)
   updateContents()
  }
 }
}

public extension SubscribedProperty where Element: PathIdentifiable {
 init(_ subjectPath: ReferenceWritableKeyPath<Publisher, Subject>) {
  self.init(subjectPath: subjectPath, keyPath: \Element.path)
 }
}

public extension SubscribedProperty where Element: Identifiable {
 init(_ subjectPath: ReferenceWritableKeyPath<Publisher, Subject>) {
  self.init(
   subjectPath: subjectPath, keyPath: \Element.id.hashValue.description
  )
 }
}

public extension SubscribedProperty {
 init(
  _ subjectPath: ReferenceWritableKeyPath<Publisher, Subject>,
  id: KeyPath<Element, AnyHashable>
 ) {
  self.init(
   subjectPath: subjectPath, keyPath: id.appending(path: \.description)
  )
 }
}

public extension ContentPublisher where Self: ContentCache {
 typealias Subscribed<Subject, Content> =
  SubscribedProperty<Self, Subject, Content> where Content: StructuredContent,
  Subject:
  MutableCollection & RangeReplaceableCollection & RandomAccessCollection,
  Subject.Element: Hashable
}

// MARK: Protocols
/// A convenience protocol for subscribing to content within a subject type
public protocol SubscribedContent {
 associatedtype Content: StructuredContent
}

public protocol PathIdentifiable: Identifiable {
 var path: String { get }
}

// MARK: Extensions
extension ObjectIdentifier: Transactional, @unchecked Sendable {
 public typealias A = Self
 public typealias B = Never
 public var source: ObjectIdentifier { self }
}

public extension Dictionary where Value: Infallible {
 @inlinable subscript(_ key: Key) -> Value {
  get { self[key, default: .defaultValue] }
  mutating set { self[key, default: .defaultValue] = newValue }
 }
}
