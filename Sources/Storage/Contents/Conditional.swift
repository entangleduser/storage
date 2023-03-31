struct ConditionalContent<A, B>: WrappedContent
where A: Content, B: Content {
 enum Storage {
  case trueContent(A)
  case falseContent(B)
 }

 let storage: Storage

 var wrappedContent: AnyContent {
  switch storage {
  case let .trueContent(content): return content.unwrapped
  case let .falseContent(content): return content.unwrapped
  }
 }
}
