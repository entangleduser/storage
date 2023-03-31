extension Traits {
 static var variadic: Self {
  var `self`: Self = .defaultValue
  self.isObservable = false
  return self
 }

 static var recursive: Self {
  var `self`: Self = .variadic
  self.isRecursive = true
  return self
 }
}

// MARK: Types that form the structure of content
struct Folder<ID: LosslessStringConvertible, Structure: Content>: RecursiveContent {
 unowned var _reflection: Reflection?
 var _traits: Traits?
 var _attributes: Attributes?
 let id: ID
 let contents: () -> Structure
 var _contents: [AnyContent] { Storage.Contents.ignored(contents) }

 init(_ name: ID, @Storage.Contents contents: @escaping () -> Structure) {
  self.id = name
  self.contents = contents
 }
}

extension Folder where Structure == EmptyContent {
 init(_ name: ID) {
  self.id = name
  self.contents = { EmptyContent() }
 }
}

/// Forms variadic content that can be modified to as a result of the closure
/// Contents within the closure are bound by the offset of the element
struct ForEach<Elements: RandomAccessCollection>: VariadicContent {
 unowned var _reflection: Reflection?
 var _traits: Traits?
 var _attributes: Attributes?
 let elements: Elements
 let result: (Elements.Element) -> AnyContent
 var _contents: [AnyContent] {
  elements.map { content in Storage.Contents.ignoredResult(element: content, result) }
 }

 init(
  _ elements: Elements,
  @Storage.Contents result: isolated
  @escaping (Elements.Element) -> some Content
 ) {
  self.elements = elements
  self.result = result
 }
}

extension Content {
 // var isForEach: Bool { Self.self is ForEach<any RandomAccessCollection, AnyContent>.Type }
}

// Applies modifiers from the group to the contents of the closure
struct Group<Contents: Content>: VariadicContent {
 unowned var _reflection: Reflection?
 var _traits: Traits?
 var _attributes: Attributes?
 let contents: () -> Contents
 var _contents: [AnyContent] { Storage.Contents.ignored(contents) }
 init(@Storage.Contents contents: @escaping () -> Contents) {
  self.contents = contents
 }
}
