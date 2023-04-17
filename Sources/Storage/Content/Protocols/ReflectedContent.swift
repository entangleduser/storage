public protocol ReflectedContent {
 var _reflection: Reflection? { get set }
}

public extension ReflectedContent {
 @_disfavoredOverload
 var _reflection: Reflection? { get { nil } set {} }
}
