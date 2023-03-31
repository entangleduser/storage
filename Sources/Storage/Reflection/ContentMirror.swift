@_exported @testable import Core
@_exported @testable import Composite
import Reflection
// @_exported import OrderedCollections
typealias ReflectionIndex = Graphex<[AnyContent]>
extension Graphex: CustomStringConvertible where Base == [AnyContent] {
 public var description: String {
  """
  Self Index: \(value), \(position), \(offset),
  Elements[\(elementRange)], Base[\(baseRange)]
  Start Index: \(
   start == self ? "Self" :
    """
    \(start.value), \(start.position), \(start.offset),
    Elements[\(start.elementRange)], Base[\(start.baseRange)]
    """
  )
  Previous Index: \(
   previous == nil ? "None" :
    "\(previous!.value), \(previous!.position), \(previous!.offset)"
  )
  Next Index: \(
   next == nil ? "None" :
    "\(next!.value), \(next!.position), \(next!.offset)"
  )
  """
 }
}

typealias AnyAttributeKey = any AttributeKey
typealias AnyResourcesKey = any ResourcesKey

extension [any ResolvedKey] {
 func contains(key: AnyResolvedKey) -> Bool {
  contains(where: { $0.description == key.description })
 }

 mutating func insert(_ key: AnyResolvedKey) {
  if !contains(key: key) { append(key) }
 }

 mutating func merge(_ other: Self) {
  for key in other where
   !contains(where: { $0.description == key.description }) {
   self.append(key)
  }
 }
}

var _mirrors = [ObjectIdentifier: [ObjectIdentifier: ContentMirror]]()
var _reflections: [ReflectionIndex: Reflection] = .empty
var _filters: [BloomFilter<String>] = .empty
var _ignore = true
var _lastOffset = 0
var _values: [[AnyContent]] = .empty
var _elements: [[ReflectionIndex]] = .empty

unowned var _publisher: AnyContentPublisher?
var _keyType: Any.Type!

/// The contents of a single content structure, established by a publisher
struct ContentMirror: Indexer {
 typealias Base = [AnyContent]
 typealias Element = ReflectionIndex
 var index: Int = _lastOffset
 var keyType: Any.Type! {
  get { _keyType }
  nonmutating set { _keyType = newValue }
 }

 var filters: [BloomFilter<String>] {
  get { _filters }
  nonmutating set { _filters = newValue }
 }

 var publisher: AnyContentPublisher! {
  get { _publisher }
  nonmutating set { _publisher = newValue }
 }

 func reset() {
  publisher = nil
  keyType = nil
 }

 init(_ contents: [AnyContent]) {
  defer { _lastOffset = index + 1 }
  // set the filter for the currently cached index for the mirror
  filters.append(.optimized(for: Reflection.filterCount))

  ReflectionIndex.initiate(
   with: contents,
   values: &_values,
   elements: &_elements,
   offset: _lastOffset
  )

  initialElement.step(callAsFunction)
 }
}

extension ContentMirror {
 var lastOffset: Int {
  get { _lastOffset }
  nonmutating set { _lastOffset = newValue }
 }

 var initialElement: ReflectionIndex {
  get { _elements[index][0] }
  set { _elements[index][0] = newValue }
 }

 var first: AnyContent {
  get { _values[index][0] }
  set { _values[index][0] = newValue }
 }
}

extension ContentMirror {
 @discardableResult
 func callAsFunction(_ element: ReflectionIndex) -> AnyContent? {
//   print(element, terminator: "\n\n")
  let info = element.value.info
  let name = info.name
  let mangledName: String = info.mangledName
  #if DEBUG
   print("→ Mirroring:", info.name)
  #endif

  func updateParent(_ reflection: Reflection) {
   #if DEBUG
    print("\(name) has a reflection")
   #endif
   if Reflection.types.contains(mangledName) {
    #if DEBUG
     print("Filtering \(name)")
    #endif
    filters[index].insert(mangledName)
   }

   // set parent immediately after setting current reflection
   if let parent =
    element.start == element ? nil : element.start.value._reflection {
    #if DEBUG
     print("\(name) has parent\n")
    #endif
    reflection.parent = parent

    guard var parent = reflection.parent else {
     fatalError("Parent missing for \(name)")
    }
    parent.add(name: mangledName)
    // merge and establish parent properties
    /// - note setting some inherited traits will cause conflicts that
    /// can be resolved
    reflection.traitsCache
     .assign(to: &element.start.value._reflection!.traitsCache)

    reflection.attributesCache
     .assign(to: &element.start.value._reflection!.attributesCache)
   } else {
    // print("\(name) has no parent reflection")
   }
  }

  // public values aren't intended to store a reflection
  if !element.value.isPublic, element.value.isDynamic {
   // assigning the reflection for all content with reflections or DynamicContent
   if _reflections[element] == nil {
    _reflections[element] =
     Reflection(
      publisher,
      keyType: keyType, subjectType: info.type, index: element
     )
    element.value._reflection = _reflections[element].unsafelyUnwrapped
   }
   guard element.value._reflection != nil
   else { fatalError("Reflection missing for \(name)") }
  }

  if let reflection = element.value._reflection {
   updateParent(reflection)

   if var enclosure = element.value as? any EnclosedContent {
    enclosure.update(reflection)
    element.value = enclosure

   } else if let identifiable = element.value as? any IdentifiableContent {
    reflection.name = identifiable.id.description

    #if DEBUG
     print("\(name) has name: \(identifiable.id.description)")
    #endif
    if mangledName == "Folder" {
     reflection.createDirectory()
    }
   } else if var modified = element.value as? any StructureModifier {
    modified.update(reflection)
    element.value = modified

   } else if mangledName != "Group" {
    addProperties(info, &element.value, with: reflection)
   }
  } else {
   if mangledName != "Array" {
    _reflections[element] =
     Reflection(
      publisher,
      keyType: keyType, subjectType: info.type, index: element
     )
    let reflection = _reflections[element].unsafelyUnwrapped
    if addProperties(info, &element.value, with: reflection) {
     updateParent(reflection)
    } else {
     _reflections[element] = nil
    }
   }
  }

  if element.value.hasContents {
   /// - remark: This usually be an array or single content array
   if let array = element.value.content as? [AnyContent] {
    element.rebase(array, callAsFunction)
   } else {
    #if DEBUG
     print("⇥ \(name) has some contents\n")
    #endif
    return element.value.content
   }
  } else if let variadic = element.value as? any VariadicContent,
            let array = variadic._contents.wrapped {
   if let traits = variadic._traits {
    element.value._reflection?.traits = traits
   }

   if let attributes = variadic._attributes {
    element.value._reflection?.attributes = attributes
   }
   element.rebase(array, callAsFunction)
  }
  #if DEBUG
   print("\(name) has no contents ⇥\n")
  #endif
  return nil
 }
}

extension ContentMirror {
 @discardableResult
 func addProperties(
  _ info: TypeInfo,
  _ content: inout AnyContent, with buffer: Reflection
 ) -> Bool {
  var hasProperty = false
  for propertyInfo in info.properties {
   let mangledName: String = .withName(for: propertyInfo.type)
   guard Reflection.properties.contains(mangledName) else { continue }
   hasProperty = true
   /** - remark: swiftui underscored implementation for dynamic properties
    (property as! any DynamicProperty)._propertyBehaviors
    (property as! any DynamicProperty).
    _makeProperty(
    in: SwiftUI._DynamicPropertyBuffer,
    container: SwiftUI._GraphValue<V>,content
    fieldOffset: Int,
    inputs: SwiftUI._GraphInputs
    ) */
   var property = propertyInfo.get(from: content) as! any ReflectedProperty

   // assigning the same reflection for all properties
   property._reflection = buffer

   property.update()
   propertyInfo.set(value: property, on: &content)

   // apply filtering
   filters[index].insert(mangledName)
   buffer.types.insert(mangledName)

   #if DEBUG
    print("\(info.name) has \(mangledName) named \(propertyInfo.name)")
   #endif
  }
  return hasProperty
 }

 @discardableResult
 func addAlias(
  _ info: TypeInfo,
  _ content: inout AnyContent, with buffer: Reflection
 ) -> Bool {
  var hasProperty = false
  for propertyInfo in info.properties {
   let mangledName: String = .withName(for: propertyInfo.type)
   guard mangledName == "Alias" else { continue }
   hasProperty = true
   /** - remark: swiftui underscored implementation for dynamic properties
    (property as! any DynamicProperty)._propertyBehaviors
    (property as! any DynamicProperty).
    _makeProperty(
    in: SwiftUI._DynamicPropertyBuffer,
    container: SwiftUI._GraphValue<V>,content
    fieldOffset: Int,
    inputs: SwiftUI._GraphInputs
    ) */
   var property = propertyInfo.get(from: content) as! any ReflectedProperty

   // assigning the same reflection for all properties
   property._reflection = buffer

   property.update()
   propertyInfo.set(value: property, on: &content)

   // apply filtering
   filters[index].insert(mangledName)
   buffer.types.insert(mangledName)

   #if DEBUG
    print("\(info.name) has \(mangledName) named \(propertyInfo.name)")
   #endif
  }
  return hasProperty
 }
}
