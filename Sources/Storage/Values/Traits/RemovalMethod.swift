/// The specific behavior when removing content
enum RemovalMethod: UInt, Infallible, @unchecked Sendable {
 static var defaultValue: Self { .trash }
 case delete, trash // , recover
}
