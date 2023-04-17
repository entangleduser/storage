public protocol ContentModifier: Content {
 associatedtype Enclosure: Content
 associatedtype Value
}

public protocol AttributeModifier: ContentModifier, ReflectedContent {}
