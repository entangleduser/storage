extension Content where Contents == Never { var content: Never { fatalError() } }
extension Never { typealias Contents = Never }
extension Never: Content {}

extension Optional: ReflectedContent where Wrapped: ReflectedContent {
 unowned var _reflection: Reflection? {
  get {
   if let content = self { return content._reflection }
   else { return nil }
  }
  set {
   if var content = self {
    content._reflection = newValue
    self = content
   }
  }
 }
}

extension Optional: Content where Wrapped: Content {}

extension Optional: WrappedContent where Wrapped: WrappedContent {
 var wrappedContent: AnyContent {
  if let content = self { return content }
  else { return EmptyContent() }
 }
}
