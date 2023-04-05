@_exported @testable import Core
@_exported @testable import Composite
@resultBuilder struct Contents: Builder {
 typealias Expression = AnyContent
}

extension Contents {
 @discardableResult
 static func mirroring<A: PublicContent>(
  @Storage.Contents contents: () -> some Content, for publisher: AnyContentPublisher
 ) -> A {
  if let content = publisher[content: A.self] { return content }
  defer { _ignore = true }
  _ignore = false
  _publisher = publisher
  _keyType = A.self

  return (contents() as? [AnyContent])?.first as? A ?? .defaultValue
 }

 static func ignored(_ closure: () -> some Content) -> FinalResult {
  defer { _ignore = false }
  _ignore = true
  let content = closure()
  return content as? [AnyContent] ?? [content]
 }

 static func ignored<A: Content>(content: A) -> A {
  defer { _ignore = false }
  _ignore = true
  return content
 }

 static func ignoredResult<Element>(
  element: Element, _ closure: (Element) -> AnyContent
 ) -> AnyContent {
  defer { _ignore = false }
  _ignore = true
  return (closure(element) as! [AnyContent]).first! as AnyContent
 }
 
 static func buildBlock(_ contents: AnyContent...) -> FinalResult {
  let array = contents.compactMap {
   let unwrapped = $0.unwrapped
   return unwrapped is EmptyContent ? nil : unwrapped
  }

  if _ignore { return array }
  if let _publisher {
   return _publisher.mirror(array)
  } else {
   return array
  }
 }

 static func buildBlock(_ content: some Content) -> some Content {
  buildBlock(content)
 }

 static func buildEither<A: Content, B: Content>(
  first: A
 ) -> ConditionalContent<A, B> {
  ConditionalContent(storage: .trueContent(first))
 }

 static func buildEither<A: Content, B: Content>(
  second: B
 ) -> ConditionalContent<A, B> {
  ConditionalContent(storage: .falseContent(second))
 }
}
