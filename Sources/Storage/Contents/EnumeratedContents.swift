/// Content that can be modified but the attributes are projected
/// Enumerated must have a binding with filter (for determining attributes)
/// Different ``EnumeratedContents`` types bind to different kinds of structures
/// but the initial input is usually `Data`
protocol EnumeratedContents: Content {}

extension EnumeratedContents {}

// MARK: Transformations and Filters for EnumeratedContent
// extension EnumeratedContents where Value: Codable {
// init(_ condition: @escaping (Resources) -> Bool) {
//  fatalError()
// }
//// @Storage.Contents func condition(
////  _ condition: @escaping (Resources) -> Bool
//// ) -> some Content {
////  self
//// }
////
// init(_ binding: Alias<[Value]?>) {
//  fatalError()
// }
//
// init(
//  first: Alias<Value?>,
//  where condition: @escaping (Resources) -> Bool
// ) {
//  self.init()
// }
//
// init(
//  _ binding: Alias<[Value]?>,
//  where condition: @escaping (Resources) -> Bool
// ) {
//  self.init()
// }
//
// init<Value>(
//  _ binding: Alias<Value?>,
//  _ keyPath: WritableKeyPath<Resources, Value>,
//  _ condition: @escaping (Value) -> Bool
// ) {
//  self.init()
// }
//// @Storage.Contents static func filter<Value>(
////  _ keyPath: WritableKeyPath<Resources, Value>,
////  _ condition: @escaping (Value) -> Bool
//// ) -> some Content {
////  self
//// }
// }
