import Core
import Composite

@resultBuilder struct Contents: Builder {
 typealias Expression = SomeContent
 static var publisher: AnyContentPublisher = DefaultPublisher.standard
}

extension Contents {
 @inline(__always) static func caching(
  for publisher: AnyContentPublisher,
  with keyType: Any.Type? = nil,
  @Storage.Contents contents: @escaping () -> some Content
 ) -> SomeContent {
  defer {
   publisher.keyType = nil
   publisher.ignore = true
   Self.publisher = DefaultPublisher.standard
  }
  publisher.keyType = keyType
  publisher.ignore = false
  Self.publisher = publisher

  return contents()
 }

 static func buildBlock(_ contents: SomeContent...) -> FinalResult {
  let array = contents.compactMap {
   let unwrapped = $0.unwrapped
   return unwrapped is EmptyContent ? nil : unwrapped
  }

  if publisher.ignore {
   return array
  } else {
   return [publisher.cache(array)]
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

extension Content {
 func ignoreContent<A>(_ closure: @escaping () -> A) -> A {
  defer { Storage.Contents.publisher.ignore = false }
  Storage.Contents.publisher.ignore = true
  return closure()
 }
}

extension ContentPublisher {
 func ignoreContent<A>(_ closure: @escaping () -> A) -> A {
  defer { Storage.Contents.publisher.ignore = false }
  Storage.Contents.publisher.ignore = true
  return closure()
 }
}
