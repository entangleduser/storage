protocol ContentModifier: Content {
 associatedtype Enclosure: Content
 associatedtype Value
}

protocol AttributeModifier: ContentModifier, ReflectedContent {}
