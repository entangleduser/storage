protocol ReflectedContent {
 var _reflection: Reflection? { get set }
}

extension ReflectedContent {
 @_disfavoredOverload
 unowned var _reflection: Reflection? { get { nil } set {} }
}
