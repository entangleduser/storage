/// The specific behavior when removing content
public enum RemovalMethod: UInt, Infallible, @unchecked Sendable {
 public static var defaultValue: Self { .trash }
 case delete, trash // , recover
}
