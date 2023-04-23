import Core
import Composite
import Reflection

public typealias ReflectionIndex = Graphex<[SomeContent]>

/// The contents of a single content structure, established by a publisher
public struct ContentMirror: Indexer {
 public typealias Base = [SomeContent]
 public typealias Element = ReflectionIndex
 var publisher: AnyContentPublisher!
 public var index: Int
 var key: AnyHashable?
 let keyType: Any.Type

 let _reflections: UnsafeMutablePointer<[ReflectionIndex: Reflection]>
 var reflections: [ReflectionIndex: Reflection] {
  unsafeAddress { UnsafePointer(_reflections) }
  nonmutating unsafeMutableAddress { _reflections }
 }

 let _properties: UnsafeMutablePointer<[UUID: (PropertyInfo, ReflectionIndex)]>
 var properties: [UUID: (PropertyInfo, ReflectionIndex)] {
  unsafeAddress { UnsafePointer(_properties) }
  nonmutating unsafeMutableAddress { _properties }
 }

 let _filter: UnsafeMutablePointer<BloomFilter<String>>
 var filter: BloomFilter<String> {
  unsafeAddress { UnsafePointer(_filter) }
  nonmutating unsafeMutableAddress { _filter }
 }

 let _values: UnsafeMutablePointer<[[SomeContent]]>
 var values: [[SomeContent]] {
  unsafeAddress { UnsafePointer(_values) }
  nonmutating unsafeMutableAddress { _values }
 }

 let _elements: UnsafeMutablePointer<[[ReflectionIndex]]>
 var elements: [[ReflectionIndex]] {
  unsafeAddress { UnsafePointer(_elements) }
  nonmutating unsafeMutableAddress { _elements }
 }

 init(
  publisher: AnyContentPublisher,
  key: AnyHashable?,
  keyType: Any.Type,
  reflections: inout [[ReflectionIndex: Reflection]],
  properties: inout [[UUID: (PropertyInfo, ReflectionIndex)]],
  filters: inout [BloomFilter<String>],
  values: inout [[SomeContent]],
  elements: inout [[ReflectionIndex]],
  _ contents: [SomeContent],
  offset: inout Int
 ) {
  defer { offset = index + 1 }
  self.publisher = publisher
  self.key = key
  self.keyType = keyType
  self.index = offset

  reflections.append([ReflectionIndex: Reflection]())
  self._reflections = withUnsafeMutablePointer(to: &reflections[index]) { $0 }

  properties.append([UUID: (PropertyInfo, ReflectionIndex)]())
  self._properties = withUnsafeMutablePointer(to: &properties[index]) { $0 }

  // set the filter for the currently cached index for the mirror
  filters.append(.optimized(for: Reflection.filterCount))
  self._filter = withUnsafeMutablePointer(to: &filters[index]) { $0 }

  self._values = withUnsafeMutablePointer(to: &values) { $0 }
  self._elements = withUnsafeMutablePointer(to: &elements) { $0 }

  ReflectionIndex.initiate(
   with: contents,
   values: &values,
   elements: &elements,
   offset: index
  )

  initialElement.step(callAsFunction)
 }
}

extension ContentMirror {
 var initialElement: ReflectionIndex {
  get { elements[index][0] }
  nonmutating set { elements[index][0] = newValue }
 }

 var first: SomeContent {
  get { values[index].first.unsafelyUnwrapped }
  nonmutating set { values[index][0] = newValue }
 }
}

public extension ContentMirror {
 @discardableResult
 func callAsFunction(_ element: ReflectionIndex) -> SomeContent? {
  let info = element.value.info
  let name = info.name
  let mangledName: String = info.mangledName

  #if DEBUG
   log("→ Mirroring:", info.name, for: .mirror, with: .subject)
  #endif

  func updateParent(_ reflection: Reflection) {
   #if DEBUG
    log("\"\(name)\" has a reflection", for: .mirror)
   #endif
   if Reflection.types.contains(mangledName) {
    #if DEBUG
     log("Filtering \"\(mangledName)\"", for: .mirror)
    #endif
    filter.insert(mangledName)
   }

   // set parent immediately after setting current reflection
   if let parent =
    element.start == element ? nil :
    element.start.value._reflection ?? reflections[element.start] {
    #if DEBUG
     log("\"\(name)\" has parent \"\(parent.keyType)\"\n", for: .mirror)
    #endif

    reflection.parent = parent

    guard var parent = reflection.parent else {
     fatalError("Parent missing for \"\(name)\"")
    }
    parent.add(name: mangledName)
    // merge and establish parent properties
    /// - note setting some inherited traits will cause conflicts that
    /// can be resolved
    reflection.traitsCache.assign(to: &parent.traitsCache)
    reflection.attributesCache.assign(to: &parent.attributesCache)
   } else {
    #if DEBUG
     log("\"\(name)\" has no parent reflection", for: .mirror)
    #endif
   }
  }

  // public values aren't intended to store a reflection
  if element.value.isDynamic {
   // assigning the reflection for all content with reflections or DynamicContent
   let reflection = Reflection(
    publisher,
    key: key,
    keyType: keyType,
    subjectType: info.type,
    index: element
   )

   if element.value._reflection == nil {
    // set stored reflection
    element.value._reflection = reflection
    if element.value._reflection == nil {
     // set detached reflection
     reflections[element] = reflection
    }
   }
   guard (element.value._reflection ?? reflections[element]) != nil
   else { fatalError("Reflection missing for \"\(name)\"") }
  }

  if var reflection = element.value._reflection ?? reflections[element] {
   updateParent(reflection)

   if let dynamic = element.value as? any DynamicContent,
      let name = dynamic._attributes.name.wrapped {
    reflection.name = name
   } else if let identifiable = element.value as? any IdentifiableContent {
    reflection.name = identifiable.id.description
    #if DEBUG
     log("\"\(name)\" has name: \(identifiable.id.description)", for: .mirror)
    #endif
   }

   if var enclosure = element.value as? any EnclosedContent {
    enclosure.update(reflection)
    element.value = enclosure
   } else if var modified = element.value as? any StructureModifier {
    modified.update()
    updateProperty(
     with: modified.identifier, &reflection
    )
    element.value = modified
   }
  }

  // exclude strucural types when updating properties
  if !["Group", "Folder", "ForEach", "Array"].contains(mangledName) {
   updateProperties(info, element, &element.value)
  }

  if element.value.hasContents {
   /// - remark: This usually be an array or single content array
   if let array = element.value.content as? [SomeContent] {
    #if DEBUG
     log("Rebasing \"\(name)\" ⇥\n", for: .mirror)
    #endif
    element.rebase(array, callAsFunction)
   } else {
    #if DEBUG
     log("⇥ \"\(name)\" has some contents\n", for: .mirror)
    #endif
    return element.value.content
   }
  } else if let variadic = element.value as? any VariadicContent {
   let contents = variadic._contents
   let array =
    contents is [[SomeContent]] ?
    (contents as! [[SomeContent]]).flatMap { $0 } : contents
   // accept contained reflections on variadic content
   if let reflection = element.value._reflection {
    reflection.traits.merge(with: variadic._traits)
    reflection.attributes.merge(with: variadic._attributes)
    reflection.setAttributes()
    if variadic._traits.contentType == .folder {
     reflection.createDirectory()
    }
   }
   #if DEBUG
    log("Rebasing \"\(name)\" ⇥ \(array)\n", for: .mirror)
   #endif
   element.rebase(array, callAsFunction)
  }
  #if DEBUG
   log("\"\(name)\" has no contents ⇥\n", for: .mirror)
  #endif
  return nil
 }
}

extension ContentMirror {
 func updateProperty(with id: UUID, _ reflection: inout Reflection) {
  guard let (info, index) = properties[id] else { fatalError() }
  var property = info.get(from: index.value) as! any ReflectedProperty
  property._reflection = reflection
  property.update()
  info.set(value: property, on: &index.value)
  let mangledName: String = .withName(for: info.type)
  reflection.add(name: mangledName)
  #if DEBUG
   log(
    """
    ✔︎ Set Identified property \'\(mangledName)\' on \"\(index.value)\" \
    named \(info.name)\n
    """,
    for: .property, with: .mirror
   )
  #endif
 }

 func updateProperties(
  _ info: TypeInfo,
  _ index: ReflectionIndex,
  _ content: inout SomeContent
 ) {
  var shouldUpdate = false
  #if DEBUG
   log(
    "⇥ Mirroring properties on \"\(info.mangledName)\"\n",
    for: .mirror, with: .property
   )
  #endif
  for propertyInfo in info.properties {
   let mangledName: String = .withName(for: propertyInfo.type)
   if let property =
    propertyInfo.get(from: content) as? any IdentifiableProperty {
    properties[property.identifier] = (propertyInfo, index)
    #if DEBUG
     log(
      """
      ⇥ Identified property \'\(mangledName)\' on \(info.name) \
      named \(propertyInfo.name)\n
      """,
      for: .mirror, with: .property
     )
    #endif
   } else if var property =
    propertyInfo.get(from: content) as? any ReflectedProperty {
    // get detached reflection
    guard var reflection = content._reflection ?? reflections[index]
    else { fatalError() }

    // assigning the same reflection for all properties
    // public content will not have a reflection but all others can have
    #if DEBUG
     log(
      "⇥ Found property \'\(mangledName)\' on \"\(info.name)\"\n",
      for: .mirror, with: .property
     )
    #endif
    property._reflection = reflection
    property.update()
    propertyInfo.set(value: property, on: &content)
    // apply filtering
    reflection.add(name: mangledName)

    shouldUpdate = true
   } else { continue }
   /** - remark: swiftui underscored implementation for dynamic properties
    (property as! any DynamicProperty)._propertyBehaviors
    (property as! any DynamicProperty).
    _makeProperty(
    in: SwiftUI._DynamicPropertyBuffer,
    container: SwiftUI._GraphValue<V>,content
    fieldOffset: Int,
    inputs: SwiftUI._GraphInputs
    ) */
  }
  if shouldUpdate {
   if content.isStructured {
    guard let reflection =
     (content._reflection ?? reflections[index])?.root else {
     fatalError()
    }
    if let root = reflection.root {
     root.traits.merge(with: reflection.traits)
     root.traits.contentType = .folder
     root.updateIfExisting()
    }
   }
  }
 }
}

// MARK: Extensions
extension Graphex: CustomStringConvertible where Base == [SomeContent] {
 public var description: String {
  let startInfo = start == self ? "start" :
   """
   \(String.withName(from: start.value)), \(start.position), \(start.offset), \
   elements[\(start.elementRange)], base[\(start.baseRange)]
   """
  let previousInfo = previous == nil ? "nil" :
   """
   \(String.withName(from: previous!.value)), \
   \(previous!.position), \(previous!.offset)
   """
  let nextInfo = next == nil ? "nil" :
   "\(String.withName(from: next!.value)), \(next!.position), \(next!.offset)"
  return """
  ↘︎\n 􀅳 \(String.withName(from: value)), \(position), \(offset), \
  elements[\(elementRange)], base[\(baseRange)]
  \(String.space)⇤ start: \(startInfo)
  \(String.space)⇠ previous: \(previousInfo)
  \(String.space)⇢ next: \(nextInfo)
  """
 }
}
