extension [AnyContent]: ReflectedContent {}
extension [AnyContent]: Content {}
typealias AnyContent = any Content
typealias AnyContentPublisher = any ContentPublisher
//
// struct AnyContent: WrappedContent {
// let wrappedContent: AnyContent
// var content: (AnyContent)?
//
// init(erasing content: some Content) {
//  self.wrappedContent = content.unwrapped
//  if content.hasContents { self.content = content }
// }
//
// init(_ value: AnyContent) { self.init(erasing: value) }
// }
